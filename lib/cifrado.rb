require 'cifrado/version'
require 'cifrado/core_ext/ruby18_base64'
require 'logger'
require 'shellwords'
require 'uri'
require 'thor'
require 'fileutils'
require 'pathname'
require 'securerandom'
require 'cifrado/config'
require 'cifrado/utils'
require 'cifrado/cli/progressbar'

module Cifrado
  
  if !defined? Log or Log.nil?
    shell = Thor::Shell::Color.new
    Log = Logger.new($stdout)
    Log.formatter = proc do |severity, datetime, progname, msg|
      if severity == 'ERROR' or severity == 'FATAL'
        "#{shell.set_color(severity, :red, true)}: #{msg}\n"
      elsif severity == 'WARN'
        "#{shell.set_color(severity, :yellow, true)}: #{msg}\n"
      elsif severity == 'INFO'
        "#{msg}\n"
      else
        "#{severity}: #{msg}\n"
      end
    end
    Log.level = Logger::INFO unless ENV['DEBUG']
    Log.debug "Initializing logger"
  end

  Cifrado::Config.instance.init_env

end

vendored_fog = File.join(File.dirname(__FILE__), 'cifrado/vendor/fog/lib')
if File.directory?(vendored_fog)
  fog_path = vendored_fog
else
  fog_path = File.join(File.dirname(__FILE__), '/../', 'vendor/fog/lib')
end

$:.insert 0, fog_path
require 'fog/openstack'
require 'cifrado/swift_client'
require 'cifrado/file_splitter'
require 'cifrado/crypto_services'
require 'cifrado/cli'
require 'cifrado/plugin'

Cifrado::Plugin.load_all
