# Xenbackup Example cofnig

XenBackup.configure do |conf|
  # host uri to connect too. Pool master if your doing that sorta thing
  conf.uri = 'https://awesomevmhost'

  # set to false to ignore (and break) SSL validation
  # This is pretty bad to do, but Xenserver ships with invalid Self Signed Certs
  conf.ssl_validate = true

  # user to connect too
  conf.user = 'root'

  # password. You could File.read some secret, or get this from env or whatever mechanism you see fit
  conf.pass = 'HurpDurp'

  # these are the vm tags, and SR tags for storing the backups
  # here vm's taged with SPOF are backed up to SR tagged with 'spof_sr'
  conf.backup = { 
    'SPOF' => 'spof_sr',
    'Super_Important' =>  'important_sr'
  }
end
