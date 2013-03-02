module Cifrado
  class CLI < Thor

    include Cifrado
    include Cifrado::Utils

    attr_reader :config

    check_unknown_options!

    class_option :username
    class_option :quiet
    class_option :password
    class_option :auth_url
    class_option :tenant
    class_option :config
    class_option :region
    class_option :insecure, :type => :boolean, :desc => "Insecure SSL connections"

    private
    def secure_password
      @config[:password] + @config[:secure_random]
    end

    def bwlimit
      (options[:bwlimit] * 1024 * 1024)/8 if options[:bwlimit]
    end

    def client_instance

      if options[:quiet] and Log.level < Logger::WARN
        Log.level = Logger::WARN
      end

      config = check_options
      if options[:insecure]
        Log.warn "SSL verification DISABLED"
      end
      client = Cifrado::SwiftClient.new :username => config[:username], 
                                        :api_key  => config[:password],
                                        :auth_url => config[:auth_url],
                                        :tenant   => config[:tenant],
                                        :region   => config[:region],
                                        :password_salt => config[:secure_random],
                                        :connection_options => { 
                                          :ssl_verify_peer => !options[:insecure] 
                                        }
      @client = client
      @config = config
      # Validate connection
      client.test_connection
      client
    end

    def check_options
      config_file = options[:config] || File.join(ENV['HOME'], '.config/cifrado/cifradorc')
      config = {}

      if File.exist?(config_file)
        begin
          Log.debug "Configuration file found: #{config_file}"
          Cifrado::Log.debug "Trying to read config file #{config_file}"
          config = YAML.load_file(config_file)
          Cifrado::Log.debug "Config #{config_file} read"
          original_config = config.dup
        rescue => e
          Cifrado::Log.error "Error loading config file"
          raise e
        end
      end

      config[:username]        = options[:username] || config[:username]
      config[:password]        = options[:password] || config[:password]
      config[:auth_url]        = options[:auth_url] || config[:auth_url] 
      config[:tenant]          = options[:tenant]   || config[:tenant] 
      config[:region]          = options[:region]   || config[:region] 
      config[:secure_random]   = config[:secure_random]
      [:username, :password, :auth_url, :tenant].each do |opt|
        if config[opt].nil?
          Log.error "#{opt.to_s.capitalize} not provided."
          Log.error "Use --#{opt.to_s.gsub('_', '-')} option or run 'cifrado setup' first."
          raise "Missing setting"
        end
      end
      unless config[:secure_random]
        raise Exception.new("secure_random key not found in #{config_file}")
      end

      config
    end

  end
end

require 'cifrado/cli/stat'
require 'cifrado/cli/download'
require 'cifrado/cli/list'
require 'cifrado/cli/post'
require 'cifrado/cli/delete'
require 'cifrado/cli/setup'
require 'cifrado/cli/upload'
require 'cifrado/cli/set_acl'
require 'cifrado/cli/jukebox'
require 'cifrado/cli/cinema'

at_exit do
  include Cifrado::Utils
  include Cifrado
  e = $!
  if e
    if e.is_a? Excon::Errors::Unauthorized
      Log.error "Unauthorized"
      Log.error "Double check the username, password and auth_url."
    elsif e.is_a? Excon::Errors::SocketError
      if e.message =~ /Unable to verify certificate|hostname (was|does) not match (with )?the server/
        Log.error "Unable to verify SSL certificate."
        Log.error "If the server is using a self-signed certificate, try using --insecure."
        Log.error "Please be aware of the security implications."
      else
        Log.error e.message
      end
    elsif e.is_a? RuntimeError
      Log.error e.message
    elsif e.is_a? Interrupt
      Log.info
      Log.info 'At your command, Sir!'
    else
      Log.fatal e.message
    end
    system 'stty echo'
    prettify_backtrace e
    exit! 1
  end
end
