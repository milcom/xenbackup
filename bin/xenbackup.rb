#!/usr/bin/env ruby
require_relative '../lib/xenbackup/client'

unless ARGV[0]
  puts 'Need a path to config file'
  exit 1
end

xb = XenBackup::Client.new(ARGV[0])

xb.backup
xb.clean_backups
