require_relative 'config'
require_relative '../xenapi/xenapi'
module XenBackup
  class Client
    attr_reader :xapi
    attr_reader :vmdata

    def initialize(config_path)
      @start_time = Time.now
      @config_path = config_path
      parse_config
      validate
      seppartor 'Config loaded'
      seppartor 'Fetching VM and SR data from pool.'

      load_vmdata
      load_srdata
      # before we backup, build a list of last backups to prune
      @cleanup = filter_template_tags([XenBackup.configuration.tag])
    end

    # clean up old backups
    def clean_backups
      puts 'Cleaning up Old backups'
      @cleanup.each do |tuple|
        ref, name = tuple
        cleanup_vm(ref, name)
      end
    end

    def backup
      XenBackup.configuration.backup.each_pair do |vm_tag, sr_tag|
        vms = filter_vm_tags([vm_tag])
        sr_refs = find_sr_by_tag(sr_tag)
        if sr_refs.nil? || sr_refs.empty?
          puts "WARN: Couldn't locate SR tagged: #{sr_tag} skipping #{vm_tag} backups"
          next
        end

        seppartor "Snapshotting all VM's with tag: '#{vm_tag}'"
        snap_refs  = snapshot_vms(vms)

        seppartor "Moving Snapshots to Backup volume tagged '#{sr_tag}'"
        move_vms(snap_refs, sr_refs)

        seppartor 'Cleaning Up snapshots.'
        snap_refs.each do |tuple|
          ref, name = tuple
          cleanup_vm(ref, name)
        end
      end
    end

    def snapshot_vms(refs)
      backup_refs = []
      refs.each do |tuple|
        ref, name = tuple
        puts "Taking Snapshot Backup for '#{name}'  #{ref}"
        
        back_name = XenBackup.configuration.tag + '-' +
                    name  +  '-' +
                    @start_time.strftime('%m%d%y')

        new_ref = xapi.VM.snapshot(ref, back_name)
        xapi.VM.set_tags(new_ref, [XenBackup.configuration.tag])
        backup_refs.push([new_ref, back_name])
      end
      backup_refs
    end

    # move vms to sr(s)
    def move_vms(refs, sr_refs)
      # TODO: this should prob be lifted
      refs.each do |tuple|
        ref, name = tuple
        # get random ref
        sr_ref = sr_refs.sample
        sr_name = 'N/A'
        sr_name = @srdata[sr_ref]['name_label']

        puts "Moving #{name} to Backup SR: '#{sr_name}' : #{sr_ref}"
        task = xapi.Async.VM.copy(ref, name, sr_ref)
        wait_on_task task
      end
    end

    private

    def seppartor(text)
      puts "\n"
      puts text
      puts '-' * 80 + "\n"
    end

    def find_sr_by_tag(tag)
      refs = []
      @srdata.each do |ref, sr|
        refs.push(ref) if sr['tags'].include?(tag)
      end
      refs
    end

    # filter_tags takes a list of tag filters to apply to the vmdata
    # returns a hash of ref: label
    #  TODO: make this more generic to handle template/snap tags optionally
    def filter_vm_tags(filters = [])
      list = []
      @vmdata.each do |ref, vm|
        if filters.all? { |t| vm['tags'].include?(t) }
          unless vm['is_a_snapshot'] == true || vm['is_a_template'] == true
            list.push([ref, vm['name_label']])
          end
        end
      end
      list
    end

    # filter templates by tags
    # returns a hash of ref: label
    def filter_template_tags(filters = [])
      list = []
      @vmdata.each do |ref, vm|
        if filters.all? { |t| vm['tags'].include?(t) }
          if vm['is_a_template'] == true
            list.push([ref, vm['name_label']])
          end
        end
      end
      list
    end

    # poweroff and clean the the vm and associated objects
    def cleanup_vm(vm_ref, name = 'N/A')
      if xapi.VM.get_power_state(vm_ref) != 'Halted'
        puts "Error: vm #{name} is running, this program shouldn't be deleting running vms"
        exit
      end
      puts "Deleting #{name}"
      puts "Removing disks attached to '#{name}' via #{vm_ref}"
      wait_tasks = []
      xapi.VM.get_VBDs(vm_ref).to_a.each do |vbd|
        next unless vbd

        puts "removing vbd: #{vbd}"
        wait_tasks << xapi.Async.VDI.destroy(xapi.VBD.get_record(vbd)['VDI'])
        wait_tasks << xapi.Async.VBD.destroy(vbd)
      end

      # wait for disk cleanup to finish up
      unless wait_tasks.empty?
        puts 'waiting for disks to cleanup'
        wait_tasks.each do |t|
          wait_on_task(t)
        end
      end

      puts 'Destroying Guest'
      task = xapi.Async.VM.destroy(vm_ref)
      wait_on_task(task)
    end

    def get_task_ref(task)
      puts "Waiting on task #{task}"
      wait_on_task(task)
      status_ = xapi.task.get_status(task)

      case status_
      when 'success'
        puts "#{status_}"
        # xapi task record returns result as  <value>OpaqueRef:....</value>
        # we want the ref. this way it will work if they fix it to return jsut the ref
        ref = xapi.task.get_result(task).match(/OpaqueRef:[^<]+/).to_s

        # cleanup our task
        xapi.task.destroy(task)
        return ref
      else
        puts("#{status_}")
        puts("ERROR: #{xapi.task.get_error_info(task)}")
      end
    end

    def wait_on_task(task)
      while xapi.task.get_status(task) == 'pending'
        xapi.task.get_progress(task)
        sleep 1
      end
    end

    # load_vms loads up a struct of all vm data so we don't have to keep doing it
    def load_vmdata
      @vmdata = xapi.VM.get_all_records
    end

    def load_srdata
      @srdata = xapi.SR.get_all_records
    end

    # validate the config params
    def validate
      %w(uri user pass).each do |attr|
        unless XenBackup.configuration.send(attr.to_sym)
          fail ArgumentError, "Config missing '#{attr}'"
        end
      end
    end

    # load the config file/class
    def parse_config
      eval(File.read(@config_path))
    rescue Exception => e
      puts "error parsing config file: #{@config_path}\n"
      puts e.message
      puts e.backtrace
      exit 1
    end

    # setup an xapi accessor
    def xapi
      @xapi ||= begin
        verify = XenBackup.configuration.ssl_validate ? :verify_peer : :verify_none
        session = XenApi::Client.new(
                                     XenBackup.configuration.uri,
                                     XenBackup.configuration.timeout,
                                     verify)
        session.login_with_password(
          XenBackup.configuration.user,
          XenBackup.configuration.pass)
        session
      end
    end

    def old_backups
      templates = []
      templates
    end
  end
end
