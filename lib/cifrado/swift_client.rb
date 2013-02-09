require 'cifrado/streaming_uploader'
require 'pathname'
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

    end

    def service
      authenticate_v2
      @service
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

    def add_manifest(container, object)
      authenticate_v2
      create_container container
      service.put_object_manifest container, object
    end

    def split_and_upload(container, object, options = {})

      Log.debug "Object size: #{humanize_bytes(File.size(object))}"

      chunks = options[:chunks]
      cache_dir = File.join(ENV['HOME'], '.cache/cifrado')
      unless File.directory?(cache_dir)
        Log.debug "Creating cache dir: #{cache_dir}"
        FileUtils.mkdir_p(cache_dir) 
      end
      tmp_cache = File.join(cache_dir, Time.now.to_f.to_s)
      Log.debug "Creating tmp cache dir: #{tmp_cache}"
      FileUtils.mkdir_p(tmp_cache)
      Log.debug "Cache directory #{tmp_cache}"

      unless chunks 
        Log.debug "Automatic chunk calculation"
        chunks = calculate_chunks object
      end
      Log.debug "Number of chunks: #{chunks}"
      splitter = FileSplitter.new object, 
                                  calculate_chunks(object), 
                                  tmp_cache
      splitter.split
      segment_files =  Dir["#{tmp_cache}/*"]
      sorted_segments = segment_files.sort do |a,b| 
        a.split("-")[-1].to_i <=> b.split("-")[-1].to_i
      end
      add_manifest container, object
      object_dir = File.dirname(object)
      count = 1
      sorted_segments.each do |s|
        Log.debug "Uploading segment: #{s} [#{count}/#{sorted_segments.size}]"
        if block_given?
          yield s
        end
        if service.directories.get(container).files.head(s)
          Log.debug "Segment #{s} already uploaded"
        else
          # fix segment target path, since segments
          # are in ~/.cache/cifrado/<tmp_cache>/*
          fixed_path = File.join(object_dir, File.basename(s)).gsub(/^\.\//,'')
          options[:source_file] = s
          upload(container, fixed_path, options)
        end
        count += 1
      end
    end

    def upload(container, object, options = {})
      # if :source_file present, object may be the destination
      # path of the object and may not be the path to the
      # real file
      source_file = options[:source_file] 
      if source_file
        real_path = source_file
      else
        real_path = object
      end
      Log.debug "Object size: #{humanize_bytes(File.size(real_path))}"

      authenticate_v2 

      uri = URI.parse File.join('/', container, object)

      storage_url = @service.credentials[:server_management_url]
      auth_token  = @service.credentials[:token]

      Log.debug "authentication OK"
      Log.debug "X-Storage-Url: #{storage_url}"

      create_container container

      if options[:progressbar]
        begin
          require 'progressbar'
          pbar = ProgressBar.new "Progress", 100
          fsize = File.size(real_path)
          count = 0
        rescue LoadError
          Log.warn "Progressbar support not available. Missing library."
          Log.warn "Continuing disabling the progressbar."
          options[:progressbar] = false
        end
      end
      
      Log.debug "Destination URI: " + storage_url + uri.path

      res = Cifrado::StreamingUploader.put(
          storage_url + uri.path,
          :headers => { 'X-Auth-Token' => auth_token }, 
          :file => File.open(real_path),
          :ssl_verify_peer => @connection_options[:ssl_verify_peer]
      ) do |size|
          if block_given?
            yield size
          elsif options[:progressbar]
           count += size
           # take care of divide by zero 
           per = 0
           if fsize == 0
             per = 100
           else
             per = (100*count)/fsize rescue 100
           end
           per = 100 if per > 100
           pbar.set per
          else
          end
        end
      if options[:progressbar]
        pbar.finish
      end
      raise res.class.to_s unless res.is_a? Net::HTTPCreated
    end
    
    private
    def create_container(container)
      storage_url = @service.credentials[:server_management_url]
      begin
        auth_token = @service.credentials[:token]
        r = Excon.put storage_url + "/#{container}", 
                      :expects => [201, 202],
                      :headers => { 'X-Storage-User' => @username, 
                                    'X-Auth-Token'   => auth_token
                                  }
        
        if r.status == 202
          Log.debug "Container #{container} already exists"
        else
          Log.debug "Container #{container} created"
        end
      rescue => e
        Log.debug e.message
        Log.debug e.backtrace.inspect
        raise "Error accesing the container: #{container}"  
      end
    end

  end

end
