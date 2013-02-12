require 'cifrado/version'
require 'logger'
require 'uri'
require 'thor'
require 'cifrado/config'
require 'cifrado/utils'

module Cifrado
  
  if !defined? Log or Log.nil?
    shell = Thor::Shell::Color.new
    Log = Logger.new($stdout)
    Log.formatter = proc do |severity, datetime, progname, msg|
      if severity == 'ERROR'
        "[Cifrado] #{shell.set_color(severity, :red, true)}: #{msg}\n"
      elsif severity == 'WARN'
        "[Cifrado] #{shell.set_color(severity, :yellow, true)}: #{msg}\n"
      else
        "[Cifrado] #{severity}: #{msg}\n"
      end
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
require 'cifrado/crypto_services'
require 'cifrado/cli'
