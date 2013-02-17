require 'cifrado/streaming_uploader'

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
      @connection_options = auth_data[:connection_options] || {}
      @service_type = auth_data[:service_type] || 'object-store'
      @endpoint_type = auth_data[:endpoint_type] || 'publicURL'

      @connection_options.each do |k, v|
        Excon.defaults[k] = v
      end
      authenticate_v2
    end

    def service
      @service
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
      object_path = options[:object_path] || object
      object_size = File.size(object)

      Log.debug "Object size: #{humanize_bytes(object_size)}"

      path = File.join('/', container, object_path)

      storage_url = @service.credentials[:server_management_url]
      auth_token  = @service.credentials[:token]

      Log.debug "X-Storage-Url: #{storage_url}"

      create_container container, true

      Log.debug "Destination URI: " + storage_url + path

      pcallback = options[:progress_callback]
      nchunk = 0
      headers = headers = { 'X-Auth-Token' => auth_token }
      if options[:headers]
        headers = headers.merge options[:headers] 
      end
      res = Cifrado::StreamingUploader.put(
          storage_url + Fog::OpenStack.escape(path),
          :headers => headers, 
          :file => File.open(object),
          :ssl_verify_peer => @connection_options[:ssl_verify_peer]
      ) { |bytes| nchunk += 1; pcallback.call(object_size, bytes, nchunk) if pcallback }

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

    def download(container, object = nil, options = {})
      if object
        download_object container, object, options
      else
        dir = service.directories.get container
        unless dir
          Log.debug "Container #{container} not found"
          raise "Container #{container} not found"
        end
        dest_dir = options[:output]
        dest_dir = Dir.pwd unless dest_dir
        dir.files.each do |f|
          # Skip segments from segmented uploads
          if f.key =~ /segments\/\d+\.\d{2}\/\d+/
            Log.debug "Skipping segment #{f.key}"
            next
          end
          options[:output] = File.join(dest_dir, f.key)
          target_dir = File.dirname options[:output] 
          unless File.directory?(target_dir)
            Log.debug "Creating target directory #{target_dir}"
            FileUtils.mkdir_p(target_dir)
          end
          download_object container, f.key, options
        end
      end
    end

    private
    def download_object(container, object, options = {})
      storage_url = @service.credentials[:server_management_url]
      auth_token  = @service.credentials[:token]
      storage_url << "/" unless storage_url =~ /\/$/
      object = object[1..-1] if object =~ /^\//

      raise ArgumentError.new "Invalid object" unless object
      path = File.join(container, object)

      uri = URI.parse storage_url + path
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      unless @connection_options[:ssl_verify_peer]
        Log.debug "Disabling SSL verification"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
      end
      #http.open_timeout = 10 # seconds
      #http.read_timeout = 10 # seconds
      Log.debug "Request URL #{uri.request_uri}"
      request = Net::HTTP::Get.new(uri.request_uri)

      headers = {
        "User-Agent" => "#{user_agent}",
        "X-Auth-Token" => auth_token
      }

      request.initialize_http_header headers

      obj_headers = service.head_object container, object
      if obj_headers
        size = obj_headers.headers['Content-Length']
      end
      
      Log.warn "Unknown content_length for #{path}" if size.nil?
      
      dest_file = options[:output]
      unless dest_file
        dest_file = File.join Dir.pwd, object
        unless File.directory?(File.dirname(dest_file))
          FileUtils.mkdir_p(File.dirname(dest_file))
        end
      end
      tmp_file = File.join Config.instance.cache_dir, "#{Time.now.to_f}.download"
      Log.debug "Downloading file to tmp file #{tmp_file}"

      res = http.request(request) do |response|
        File.open(tmp_file, "wb") do |file|
          response.read_body do |segment|
            if options[:progress_callback]
              options[:progress_callback].call segment.length
            end
            file.write(segment)
          end
        end
      end

      if res.is_a? Net::HTTPOK
        Log.debug "Moving download tmp file to #{dest_file}"
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
                                  :openstack_service_type  => @service_type,
                                  :openstack_endpoint_type => @endpoint_type 
    end



  end

end
