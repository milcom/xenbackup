# xenbackup
Simple App to manage xenserver VM backups via Tagging

## Usage
An example config is provided. Modify to your taste then run xenbackup with the path to your config

     $ ./bin/xenbackup.rb test_config.rb
     
     Config loaded
     --------------------------------------------------------------------------------
     
     Fetching VM and SR data from pool.
     --------------------------------------------------------------------------------
     
     Snapshotting all VM's with tag: 'testing_backups'
     --------------------------------------------------------------------------------
     Starting Snap Backup for 'etcd07'  OpaqueRef:53154495-69f9-91d4-d232-afc1fac721f7
     Tagging backup
     
     Moving Snapshots to Backup volume tagged 'spof_sr'
     --------------------------------------------------------------------------------
     Moving xenbackup-etcd07 to Backup SR: OpaqueRef:2a7fdd0d-a057-a4cd-cb79-92fc4473ebe8
     
     Cleaning Up snapshots.
     --------------------------------------------------------------------------------
     Deleting xenbackup-etcd07
     Removing disks attached to 'xenbackup-etcd07' via OpaqueRef:89a73de1-d49c-f21e-4c7c-4b08a4966406
     removing vbd: OpaqueRef:f17fcd08-df53-5865-9e42-c142bca7574b
     waiting for disks to cleanup
     Destroying Guest
     Cleaning up Old backups
     Deleting xenbackup-etcd07
     Removing disks attached to 'xenbackup-etcd07' via OpaqueRef:fdba2233-de11-caad-6dea-5e4fc4148263
     removing vbd: OpaqueRef:b1780667-a534-df4e-0016-13b972906fab
     waiting for disks to cleanup
     Destroying Guest

