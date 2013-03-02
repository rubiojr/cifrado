module Cifrado
  class CLI

    desc "upload CONTAINER FILE1 [FILE2] ...",
         "Upload files or directories"
    option :encrypt,
           :desc => 'Encrypt files when uploading'

    option :segments, 
           :type => :numeric, 
           :desc => "Split the data into segments"

    option :strip_path, 
           :type => :boolean,
           :desc => 'Strip path from file when uploading'

    option :progressbar,
           :default => :fancy,
           :desc => 'Progressbar style'

    option :bwlimit,
           :type => :numeric,
           :desc => 'Limit the bandwidth available for uploads'

    option :force, 
           :type => :boolean,
           :desc => 'Overwrite files when uploading'
    def upload(container, *args)

      if args.empty?
        help 'upload'
        raise "No files specified"
      end

      uploaded = []
      args.each do |file|
        unless file and File.exist?(file)
          raise "File '#{file}' does not exist"
        end

        client = client_instance 

        tstart = Time.now
        files = []
        if File.directory?(file)
          files = Dir["#{file}/**/*"].reject { |f| File.directory?(f) }
        else
          files << file
        end

        files.each do |f|
          begin
            if options[:segments]
              uploaded << split_and_upload(client, container, f)
            else
              headers = client.head container, clean_object_name(f)
              if headers
                if headers['Etag'] == Digest::MD5.file(f).to_s
                  if options[:force]
                    Log.warn "File #{f} already uploaded and MD5 matches."
                    Log.warn "Since --force was used, uploading it again."
                    uploaded << upload_single(client, container, f)
                  else
                    Log.warn "File #{f} already uploaded and MD5 matches, skipping."
                  end
                else
                  Log.warn "File #{f} already uploaded, but it has changed."
                  if options[:force]
                    Log.warn "Overwriting it as requested (--force)."
                    uploaded << upload_single(client, container, f)
                  else
                    Log.warn "Since --force was not used, skipping it."
                  end
                end
              else
                uploaded << upload_single(client, container, f)
              end
            end
          rescue Errno::ENOENT => e
            Log.error "Error uploading #{f}: " + e.message
          end
        end
      end
      uploaded.flatten
    end
    
    private
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

        case client.match(segment, container + "_segments", obj_path)
        when 1
          Log.warn 'Segment already uploaded, skipping.'
          File.delete segment
          next
        when 2
          Log.warn 'Segment already uploaded but looks different. Updating.'
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
      
      if options[:encrypt]
        Log.debug "Deleting temporal encrypted file #{out}"
        File.delete out 
      end
      
      if segments_uploaded.size == 0
        Log.warn 'All the segments have been previously uploaded.'
        Log.warn 'Skipping manifest creation.'
        return segments_uploaded
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

      segments_uploaded
    end

  end
end
