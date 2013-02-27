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

    def upload_single(client, container, object)
      fsize = File.size(object)
      fbasename = File.basename(object)
      Log.info "Uploading #{object} (#{humanize_bytes(fsize)})"

      pb = Progressbar.new 1, 1, :style => options[:progressbar]

      config = Cifrado::Config.instance
      object_path = object
      object_path = File.basename(object) if options[:strip_path]
      if cs = needs_encryption
        encrypted_file = File.join(config.cache_dir, File.basename(object))
        Log.debug "Writing encrypted file to #{encrypted_file}"
        encrypted_output = cs.encrypt object, 
                                      encrypted_file
        encrypted_name = encrypt_filename object, secure_password
        client.upload container, 
                      encrypted_output, 
                      :headers => { 
                        'X-Object-Meta-Encrypted-Name' => encrypted_name
                      },
                      :object_path => File.basename(encrypted_output),
                      :progress_callback => pb.block,
                      :bwlimit => bwlimit
        object_path = File.basename(encrypted_output)
        File.delete encrypted_output 
      else
        client.upload container, 
                      object,
                      :object_path => object_path,
                      :progress_callback => pb.block,
                      :bwlimit => bwlimit
      end
      object_path
    end

    def needs_encryption
      return nil unless options[:encrypt]

      tokens = options[:encrypt].split(':')
      etype = tokens.first
      if etype == 'a'
        recipient = tokens[1..-1].join(':')
        CryptoServices.new :type => :asymmetric, 
                                    :recipient => recipient, 
                                    :encrypt_name => true
      elsif etype == 's' or etype == 'symmetric'
        if etype == 'symmetric'
          Log.info "Password to encrypt the data required"
          system 'stty -echo'
          passphrase = ask("Enter passphrase:")
          puts
          passphrase2 = ask("Repeat passphrase:")
          puts
          if passphrase != passphrase2
            raise 'Passphrase does not match'
          end
          system 'stty echo'
        else
          passphrase = tokens[1..-1].join(':')
        end
        unless passphrase
          raise "Invalid symmetric encryption passprase"
        end
        CryptoServices.new :type => :symmetric, 
                                    :passphrase => passphrase, 
                                    :encrypt_name => true
      else
        raise "Invalid encryption type #{etype}."
      end
    end

    def encrypt_if_required(file)
      if cs = needs_encryption
        Log.debug "Encrypting object #{file}"
        cache_dir = Cifrado::Config.instance.cache_dir
        encrypted_output = cs.encrypt file, 
                                      File.join(cache_dir, File.basename(file))
      else
        file
      end
    end

    # FIXME: needs refactoring
    def split_and_upload(client, container, object)
      fbasename = File.basename(object)

      # Encrypts the file if required
      out = encrypt_if_required(object)

      splitter = FileSplitter.new out, options[:segments]

      if options[:encrypt]
        target_manifest = File.basename(out)
      else
        target_manifest = (options[:strip_path] ? \
                              File.basename(object) : clean_object_name(object))
      end

      Log.info "Segmenting file, #{options[:segments]} segments..."
      Log.info "Uploading #{fbasename} segments"

      segments_uploaded = []
      splitter.split do |n, segment|
        segment_size = File.size segment
        hsegment_size = humanize_bytes segment_size
        Log.info "Uploading segment #{n}/#{options[:segments]} (#{hsegment_size})"

        segment_number = "%08d" % n
        if options[:encrypt]
          suffix = splitter.chunk_suffix + segment_number
          obj_path = File.basename(out) + suffix
          Log.debug "Encrypted object path: #{obj_path}"
          encrypted_name = encrypt_filename object + suffix,
                                            secure_password
          headers = { 
            'X-Object-Meta-Encrypted-Name' => encrypted_name 
          }
        else
          obj_path = object + splitter.chunk_suffix + segment_number
          Log.debug "Unencrypted object path #{obj_path}"
          if options[:strip_path]
            obj_path = File.basename(obj_path) 
            Log.debug "Stripping path from object: #{obj_path}"
          end
          Log.debug "Uploading segment #{obj_path} (#{segment_size} bytes)..."
          headers = {}
        end

        pb = Progressbar.new options[:segments],
                             n,
                             :style => options[:progressbar]

        client.upload container + "_segments", 
                      segment,
                      :headers => headers,
                      :object_path => obj_path,
                      :progress_callback => pb.block,
                      :bwlimit => bwlimit

        File.delete segment
        segments_uploaded << obj_path
      end
      
      # We need this for segmented uploads
      Log.debug "Adding manifest path #{target_manifest}"
      xom = "#{Fog::OpenStack.escape(container + '_segments')}/" +
            "#{Fog::OpenStack.escape(target_manifest)}"
      headers = { 'X-Object-Manifest' => xom }
      if options[:encrypt]
        encrypted_name = encrypt_filename object, secure_password
        headers['X-Object-Meta-Encrypted-Name'] = encrypted_name
      end
      client.create_directory container
      client.service.put_object_manifest container, 
                                         target_manifest,
                                         headers  
      segments_uploaded.insert 0, target_manifest

      # Delete temporal encrypted file created by GPG
      if options[:encrypt]
        Log.debug "Deleting temporal encrypted file #{out}"
        File.delete out 
      end
      segments_uploaded
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
