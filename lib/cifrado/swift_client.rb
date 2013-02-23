require 'cifrado/streaming_uploader'
require 'cifrado/streaming_downloader'

module Cifrado 
  
  class SwiftClient

    include Cifrado::Utils
    attr_reader :api_key
    attr_reader :username
    attr_reader :auth_url

    def initialize(auth_data = {})
      @username = auth_data[:username]
      @api_key  = auth_data[:api_key]
      @auth_url = auth_data[:auth_url]
      @tenant   = auth_data[:tenant]
      @connection_options = auth_data[:connection_options] || {}
      @service_type = auth_data[:service_type] || 'object-store'
      @endpoint_type = auth_data[:endpoint_type] || 'publicURL'

      @connection_options.each do |k, v|
        Excon.defaults[k] = v
      end
    end

    def test_connection
      authenticate_v2
    end

    def service
      @service ||= authenticate_v2
    end

    def set_acl(acl, container, object = nil)
      if object
        raise NotImplementedError.new
      else
        service.request :path => Fog::OpenStack.escape(container), 
                        :headers => { 'X-Container-Read' => acl },
                        :expects => [201, 202],
                        :method  => 'PUT'
      end
    end

    def head(url, params = {})
      params[:headers] = (params[:headers] || {}).merge(
        { 'X-Auth-Token' => service.credentials[:token] }
      )
      Excon.head url, params
    end

    def encrypted_upload(container, object, options = {})
      cipher = CryptoEngineAES.new @api_key
      encrypted_name = cipher.encrypt object
      options[:headers] ||= {}
      options[:headers]['X-Object-Meta-Encrypted-Name'] = encrypted_name
      upload container, object, options
    end

    def upload(container, object, options = {})

      raise ArgumentError.new("Invalid container") if container.nil?
      raise ArgumentError.new("Invalid object") if object.nil?

      # if :source_file present, object may be the destination
      # path of the object and may not be the path to the
      # real file
      object_path = clean_object_name(options[:object_path] || object)
      object_size = File.size(object)

      Log.debug "Object size: #{humanize_bytes(object_size)}"

      path = File.join('/', container, object_path)

      Log.debug "X-Storage-Url: #{@storage_url}"

      create_container container, true

      Log.debug "Destination URI: " + @storage_url + path

      pcallback = options[:progress_callback]
      nchunk = 0
      headers = { 'X-Auth-Token' => @auth_token }
      if mime = mime_type(object)
        headers['Content-Type'] = mime
      end
      if options[:headers]
        headers = headers.merge options[:headers] 
      end
      if pcallback
        res = Cifrado::StreamingUploader.put(
            @storage_url + Fog::OpenStack.escape(path),
            :headers => headers, 
            :file => File.open(object),
            :ssl_verify_peer => @connection_options[:ssl_verify_peer],
            :bwlimit => options[:bwlimit]
        ) { |bytes| pcallback.call(object_size, bytes) }
      else
        res = Cifrado::StreamingUploader.put(
            @storage_url + Fog::OpenStack.escape(path),
            :headers => headers, 
            :file => File.open(object),
            :ssl_verify_peer => @connection_options[:ssl_verify_peer],
            :bwlimit => options[:bwlimit]
        ) 
      end

      Log.debug "Upload response #{res.class}"
      # Wrap Net::HTTPResponse in a Excon::Response Object
      r = Excon::Response.new :body => res.body,
                              :headers => res.to_hash,
                              :status => res.code.to_i
      r
    end

    def user_agent
      "Cifrado #{Cifrado::VERSION}"
    end
    
    def stream(container, object, options = {})
      o = options.dup
      o[:stream] = true
      download_object container, object, o
    end

    def download(container, object = nil, options = {})
      if object
        download_object container, object, options
      else
        dir = service.directories.get container
        unless dir
          Log.debug "Container #{container} not found"
          raise "Container #{container} not found"
        end
        dest_dir = options[:output] || Dir.pwd
        unless File.directory?(dest_dir)
          raise ArgumentError.new "Directory #{dest_dir} does not exist"
        end
        dir.files.each do |f|
          # Skip segments from segmented uploads
          if f.key =~ /segments\/\d+\.\d{2}\/\d+/
            Log.debug "Skipping segment #{f.key}"
            next
          end
          unless options[:decrypt] == true
            options[:output] = File.join(dest_dir, f.key)
          end
          download_object container, f.key, options
        end
        Excon::Response.new :status => 200
      end
    end

    private
    def download_object(container, object, options = {})
      storage_url = service.credentials[:server_management_url]
      storage_url << "/" unless storage_url =~ /\/$/
      object = object[1..-1] if object =~ /^\//

      raise ArgumentError.new "Invalid object" unless object
      path = File.join(container, object)

      dest_file = options[:output]
      if dest_file 
        if File.directory?(dest_file)
          dest_file = File.join dest_file, object
        end
      else
        Log.debug ":output option not specified, using current dir"
        dest_file = File.join Dir.pwd, object
      end

      tmp_file = File.join Config.instance.cache_dir, "#{Time.now.to_f}.download"
      Log.debug "Downloading file to tmp file #{tmp_file}"

      headers = {
        "User-Agent" => "#{user_agent}",
        "X-Auth-Token" => @auth_token
      }
      res = StreamingDownloader.get storage_url + Fog::OpenStack.escape(path),
                                    tmp_file,
                                    :progress_callback => options[:progress_callback],
                                    :connection_options => @connection_options,
                                    :headers => headers,
                                    :bwlimit => options[:bwlimit],
                                    :stream => options[:stream]

      #
      # Try to decrypt the file if it was encrypted
      #
      if options[:decrypt]
        encrypted_name = res['X-Object-Meta-Encrypted-Name']
        if encrypted_name
          Log.debug 'Encrypted filename found, decrypting'
          decrypted_name = decrypt_filename encrypted_name, @api_key
          Log.debug "Decrypted filename: #{decrypted_name}"
          if options[:output].nil?
            dest_file = File.join(Dir.pwd, decrypted_name)
          elsif File.directory?(options[:output])
            dest_file = File.join(options[:output], decrypted_name)
          else
          end
          Log.debug "Decrypted file output: #{dest_file}"
          cs = CryptoServices.new :passphrase => options[:passphrase] 
          tmp_file = cs.decrypt tmp_file, tmp_file + '.decrypted' 
        else
          Log.warn 'X-Object-Meta-Encrypted-Name header not found in object'
          Log.warn 'Trying to decrypt anyways'
        end
      end

      # if download is OK, move the file from cache to :output
      # or to the current directory
      if res.is_a? Net::HTTPOK
        Log.debug "Moving download tmp file to #{dest_file}"
        # Object name may have a path, create target directory 
        # if not available
        target_dir = File.dirname(dest_file)
        unless File.directory?(target_dir)
          Log.debug "Creating target directory #{target_dir}"
          FileUtils.mkdir_p(target_dir)
        end
        FileUtils.mv tmp_file, dest_file
      else
        Log.debug "Download failed, deleting tmp file"
        FileUtils.rm tmp_file 
      end
      Excon::Response.new :body => res.body,
                          :headers => res.to_hash,
                          :status => res.code.to_i
    end
    
    def create_container(container, wait_for_it = false )
      dir = service.directories.create :key => container
      # Wait for the new container to be available
      dir.wait_for { !service.directories.get(container).nil? } if wait_for_it
    end
    
    def add_manifest(container, object)
      create_container container
      service.put_object_manifest container, object
    end
    def authenticate_v2
      return if @service
      
      Log.debug "Using keystone authentication"
      @service = Fog::Storage.new :provider => 'OpenStack',
                                  :openstack_auth_url => @auth_url,
                                  :openstack_username => @username,
                                  :openstack_api_key  => @api_key,
                                  :openstack_tenant   => @tenant,
                                  :openstack_service_type  => @service_type,
                                  :openstack_endpoint_type => @endpoint_type 
      @storage_url = @service.credentials[:server_management_url]
      @auth_token  = @service.credentials[:token]
      @service
    end



  end

end
