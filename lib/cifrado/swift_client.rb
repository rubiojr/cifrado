require 'cifrado/streaming_uploader'
require 'fileutils'

module Cifrado 
  
  class SwiftClient

    include Cifrado::Utils

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

      Log.debug "authentication OK"
      Log.debug "X-Storage-Url: #{storage_url}"

      create_container container, true

      Log.debug "Destination URI: " + storage_url + path

      pcallback = options[:progress_callback]
      nchunk = 0
      res = Cifrado::StreamingUploader.put(
          storage_url + Fog::OpenStack.escape(path),
          :headers => { 'X-Auth-Token' => auth_token }, 
          :file => File.open(object),
          :ssl_verify_peer => @connection_options[:ssl_verify_peer]
      ) { |bytes| nchunk += 1; pcallback.call(object_size, bytes, nchunk) if pcallback }

      Log.debug "Upload response #{res.class}"
      res.code.to_i
    end
    
    private
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
