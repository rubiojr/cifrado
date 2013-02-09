require 'cifrado/version'
require 'logger'
require 'uri'
require 'cifrado/utils'

module Cifrado
  
  if !defined? Log or Log.nil?
    Log = Logger.new($stdout)
    Log.formatter = proc do |severity, datetime, progname, msg|
        "[Cifrado] #{severity}: #{msg}\n"
    end
    Log.level = Logger::INFO unless ENV['DEBUG']
    Log.debug "Initializing logger"
  end

end

fog_path = File.join(File.dirname(__FILE__), '/../', 'vendor/fog/lib')
$:.insert 0, fog_path
require 'fog/openstack'
require 'cifrado/swift_client'
require 'cifrado/file_splitter'
