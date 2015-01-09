# Xenbackup Example config

XenBackup.configure do |conf|
  # host uri to connect too. Pool master if your doing that sorta thing
  # default: http://localhost
  conf.uri = 'https://awesomevmhost'

  # set to false to ignore (and break) SSL validation
  # This is pretty bad to do, but Xenserver ships with invalid Self Signed Certs
  # default: true
  # conf.ssl_validate = true

  # set the HTTP timeout for xapi commands
  # default: 30
  # conf.timeout = 120

  # user to connect too
  # default: root
  conf.user = 'root'

  # password. You could File.read some secret, or get this from env or whatever mechanism you see fit
  # default: nil
  conf.pass = 'HurpDurp'

  # these are the vm tags, and SR tags for storing the backups
  # here vm's taged with SPOF are backed up to SR tagged with 'spof_sr'
  # default: nil
  conf.backup = {
    'SPOF' => 'spof_sr',
    'Super_Important' =>  'important_sr'
  }

  # Tag used to denote VM's backuped up with xenbackup.
  # This is important in that the 'cleanup' action will consider any vm with this tag for deletion
  # default: xenbackup
  # conf.tag = xenbackup

end
