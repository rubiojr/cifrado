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
  end
end
