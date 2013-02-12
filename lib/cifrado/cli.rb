module Cifrado
  class CLI < Thor

    include Cifrado
    include Cifrado::Utils

    check_unknown_options!

    class_option :username
    class_option :password
    class_option :auth_url

    desc "stat [CONTAINER] [OBJECT]", "Displays information for the account, container, or object."
    option :insecure, :type => :boolean
    def stat(container = nil, object = nil)
      client = client_instance options
      creds = client.service.credentials

      uri = URI.parse creds[:server_management_url]
      Log.debug "HEAD #{uri.to_s}/#{[container, object].compact.join("/")}"

      r = client.head "#{uri.to_s}/#{[container, object].compact.join("/")}"

      puts "Account:".ljust(30) + File.basename(uri.path)
      r.headers.each do |k, v| 
        if k == 'X-Timestamp'
          puts "#{(k + ":").ljust(30)}#{v} (#{unix_time(v)})" 
        elsif k == 'X-Account-Bytes-Used' or k == 'Content-Length'
          puts "#{(k + ":").ljust(30)}#{v} (#{humanize_bytes(v)})" 
        else
          puts "#{(k + ":").ljust(30)}#{v}" 
        end
      end
      r.headers
    end

    desc "download [CONTAINER] [OBJECT]", "Download container, objects"
    option :insecure, :type => :boolean
    def download(container, object = nil)
      Log.warn "Not implemented :("
    end

    desc "list [CONTAINER]", "List containers and objects"
    option :insecure, :type => :boolean
    def list(container = nil)
      client = client_instance options
      if container
        dir = client.service.directories.get container
        if dir
          Log.info "Listing objects in '#{container}'"
          files = dir.files
          files.each { |f| puts f.key }
          files
        else
          Log.error "Container '#{container}' not found"
        end
      else
        Log.info "Listing containers"
        directories = client.service.directories
        directories.each { |d| puts d.key }
        directories
      end
    end

    desc "container-add CONTAINER [DESCRIPTION]", "Create a container"
    option :insecure, :type => :boolean
    def container_add(container, description = '')
      client = client_instance options
      client = Cifrado::SwiftClient.new :username => config[:username], 
                                        :api_key  => config[:password],
                                        :auth_url => config[:auth_url],
                                        :connection_options => { :ssl_verify_peer => !options[:insecure] }
      client.service.directories.create :key => container, 
                                        :description => description
    end

    desc "delete CONTAINER [OBJECT]", "Delete specific container or object"
    def delete(container, object = nil)
    end

    desc "cache-clean", "Empty Cifrado's cache directory"
    def cache_clean
      Log.info "Cleaning cache dir #{Config.instance.cache_dir}"
      Dir["#{Config.instance.cache_dir}/*.encrypted"].each { |f| File.delete f }
      Dir["#{Config.instance.cache_dir}/*-chunk-*"].each { |f| File.delete f }
      Dir["#{Config.instance.cache_dir}/*.md5"].each { |f| File.delete f }
    end

    desc "setup", "Initial Cifrado configuration"
    def setup
      check_options options
      Log.debug "Setup done"
    end

    desc "set-acl CONTAINER", 'Set an ACL on containers and objects'
    option :acl, :type => :string, :required => true
    option :insecure, :type => :boolean
    def set_acl(container, object = nil)
      config = check_options options
      client = Cifrado::SwiftClient.new :username => config[:username], 
                                        :api_key  => config[:password],
                                        :auth_url => config[:auth_url],
                                        :connection_options => { :ssl_verify_peer => !options[:insecure] }
      client.set_acl options[:acl], container
    end

    desc "upload CONTAINER FILE", "Upload a file"
    option :encrypt, :desc => 'Encrypt: a:recipient (asymmetric) or symmetric'
    option :segments, :type => :numeric, :desc => "Split the data in segments"
    option :insecure, :type => :boolean, :desc => "Insecure SSL connections"
    option :strip_path, :type => :boolean
    option :no_progressbar,   :type => :boolean
    option :fast_progressbar, :type => :boolean
    def upload(container, file)

      unless File.exist?(file)
        Log.error "File '#{file}' does not exist"
        exit 1
      end

      config = check_options options
      begin 
        client = Cifrado::SwiftClient.new :username => config[:username], 
                                          :api_key  => config[:password],
                                          :auth_url => config[:auth_url],
                                          :connection_options => { :ssl_verify_peer => !options[:insecure] }


        ENV['CIFRADO_FAST_PROGRESSBAR'] = 'yes' if options[:fast_progressbar]

        tstart = Time.now
        uploaded = nil
        if options[:segments]
          uploaded = split_and_upload client, container, file, options
        else
          uploaded = upload_single client, container, file, options
        end
        tend = Time.now
        Log.info "Time taken #{(tend - tstart).round} s."
        uploaded

      rescue Excon::Errors::Unauthorized => e
        Log.error set_color("Unauthorized.", :red, true)
        Log.error "Double check the username, password and auth_url."
      rescue Excon::Errors::SocketError => e
        if e.message =~ /Unable to verify certificate/
          Log.error "Unable to verify certificate. Try using --insecure."
        end
      rescue Exception => e
        Log.error e.message
        Log.debug e.backtrace.inspect
      ensure
        system 'stty echo icanon'
      end
    end

    private
    def client_instance(options)
      begin
        config = check_options options
        client = Cifrado::SwiftClient.new :username => config[:username], 
                                          :api_key  => config[:password],
                                          :auth_url => config[:auth_url],
                                          :connection_options => { 
                                            :ssl_verify_peer => !options[:insecure] 
                                          }
        return client
      rescue Excon::Errors::Unauthorized => e
        Log.error set_color("Unauthorized.", :red, true)
        Log.error "Double check the username, password and auth_url."
      rescue Excon::Errors::SocketError => e
        if e.message =~ /Unable to verify certificate/
          Log.error "Unable to verify certificate. Try using --insecure."
        end
      end
      exit 1
    end

    def check_options(options)
      config_file = File.join(ENV['HOME'], '.cifradorc')
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
          Cifrado::Log.error e.message
        end
      end

      config[:username] = options[:username] || config[:username] || ask('username:')
      if options[:password] or config[:password]
        config[:password] = options[:password] || config[:password]
      else
        system 'stty -echo -icanon'
        config[:password] = ask('password:')
        system 'stty echo icanon'
        puts
      end
      config[:auth_url] = options[:auth_url] || config[:auth_url] || ask('auth_url:')

      unless File.exist?(config_file)
        puts
        puts "Cifrado can save this settings in #{ENV['HOME']}/.cifradorc"
        puts "for later use."
        puts "The settings (password included) are saved unencrypted."
        puts
        if yes? "Do you want to save these settings?"
          File.open(config_file, 'w') do |f| 
            f.puts config.to_yaml
            f.chmod 0600
          end
          @settings_saved = true
        end
      end

      if original_config != config and !@settings_saved
        puts "username, password and/or auth_url changed"
        if yes? "Do you want to save the NEW settings?"
          File.open(config_file, 'w') { |f| f.puts config.to_yaml }
        end
      end

      config
    end

    def upload_single(client, container, object, options)
      fsize = File.size(object)
      fbasename = File.basename(object)
      Log.info "Uploading #{fbasename} (#{humanize_bytes(fsize)})"
      unless options[:no_progressbar]
        cb = progressbar_callback(1, 1)
      else
        cb = nil
      end
      config = Cifrado::Config.instance
      object_path = object
      object_path = File.basename(object) if options[:strip_path]
      if cs = needs_encryption(options)
        encrypted_file = File.join(config.cache_dir, File.basename(object))
        Log.debug "Writing encrypted file to #{encrypted_file}"
        encrypted_output = cs.encrypt object, 
                                      encrypted_file
        client.upload container, 
                      encrypted_output, 
                      :object_path => File.basename(encrypted_output),
                      :progress_callback => cb
        object_path = File.basename(encrypted_output)
        File.delete encrypted_output 
      else
        client.upload container, 
                      object,
                      :object_path => object_path,
                      :progress_callback => cb
      end
      object_path
    end

    # FIXME: needs refactoring
    def progressbar_callback(total = 0, count = 0)
      @progressbar_count = 0 
      @progressbar_finished = false
      Log.debug "Calling progressbar_callback"

      if ENV['CIFRADO_FAST_PROGRESSBAR']
        if total != 1
          title = "[#{count}/#{total}]"
        else
          title = ""
        end
        #Log.warn 'Using dummy progressbar callback'
        return Proc.new do |tbytes, bytes, nchunk| 
          @progressbar_count += bytes
          percentage = ((@progressbar_count*100.0/tbytes))
          if ((percentage % 10) < 0.1) and @progressbar_count <= tbytes
            print "\r"
            print "Progress (#{percentage.round}%) #{title}: "
            print '.' * (percentage/10).floor
          end
          if (@progressbar_count + bytes) >= tbytes and !@progressbar_finished
            @progressbar_finished = true
            percentage = 100
            print "\r"
            print "Progress (#{percentage.round}%) #{title}: "
            print '.' * (percentage/10).floor
            puts
          end
        end
      end

      title = (total == 1 ? 'Progress' : "Segment [#{count}/#{total}]")

      if RUBY_VERSION =~ /1\.8/
        # See https://github.com/jfelchner/ruby-progressbar/pull/25
        Log.warn "Progressbar performance is very poor under Ruby 1.8"
        Log.warn "If you are getting low throughtput when uploading"
        Log.warn  "upgrade to Ruby 1.9.X or use --no-progressbar"
      end
      require 'ruby-progressbar'
      @progressbar = ProgressBar.create :title => title, :total => 100
      cb = Proc.new do |total, bytes, nchunk| 
        @progressbar_count += bytes
        unless @progressbar_count > total
          increment = (bytes*100.0)/total
          percentage = ((@progressbar_count*100.0/total)).round
          @progressbar.title = "#{title} (#{percentage}%)"
          @progressbar.progress += increment 
          if (@progressbar_count + bytes) >= total
            @progressbar.finish
          end
        end
      end
    end

    def needs_encryption(options)
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
          system 'stty -echo -icanon'
          passphrase = ask("password:")
          system 'stty echo icanon'
          puts
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

    # FIXME: needs refactoring
    def split_and_upload(client, container, object, options)
      fbasename = File.basename(object)

      if cs = needs_encryption(options)
        Log.debug "Encrypting object #{object}"
        cache_dir = Cifrado::Config.instance.cache_dir
        encrypted_output = cs.encrypt object, 
                                      File.join(cache_dir, File.basename(object))
        splitter = FileSplitter.new encrypted_output, options[:segments]
        target_manifest = File.basename(encrypted_output)
      else
        splitter = FileSplitter.new object, options[:segments]
        target_manifest = (options[:strip_path] ? File.basename(object) : object)
      end

      Log.info "Segmenting file, #{options[:segments]} segments..."
      segments = splitter.split

      Log.info "Uploading #{fbasename} segments"
      count = 0
      segments_added = []
      segments.each do |segment|
        count += 1
        segment_size = File.size segment
        hsegment_size = humanize_bytes segment_size

        unless options[:no_progressbar]
          cb = progressbar_callback(segments.size, count)
        else
          Log.info "Uploading segment #{count}/#{segments.size} (#{hsegment_size})"
          cb = nil
        end
        segment_number = segment.split(splitter.chunk_suffix).last
        if defined? :encrypted_output and encrypted_output
          Log.debug "Stripping path from encrypted segment #{encrypted_output}"
          obj_path = File.basename(encrypted_output) + splitter.chunk_suffix + segment_number
        else
          obj_path = object + splitter.chunk_suffix + segment_number
          Log.debug "Stripping path from segment #{obj_path}"
          if options[:strip_path]
            obj_path = File.basename(obj_path) 
          end
        end

        Log.debug "Uploading segment #{obj_path} (#{segment_size} bytes)..."
        client.upload container, 
                      segment, 
                      :object_path => obj_path,
                      :progress_callback => cb
        segments_added << obj_path
      end
      
      # We need this for segmented uploads
      Log.debug "Adding manifest #{object}"
      client.service.put_object_manifest container, target_manifest
      segments_added.insert 0, target_manifest

      # Delete temporal encrypted file created by GPG
      if options[:encrypt]
        Log.debug "Deleting temporal encrypted file #{encrypted_output}"
        File.delete encrypted_output
      end
      segments_added
    end

  end
end
