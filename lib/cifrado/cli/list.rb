module Cifrado
  class CLI
  # @returns [Array] a list of Fog::OpenStack::File or
    # Fog::OpenStack::Directory
    #
    desc "list [CONTAINER]", "List containers and objects"
    option :list_segments, :type => :boolean
    option :decrypt_filenames, :type => :boolean
    option :display_hash, :type => :boolean
    def list(container = nil)
      client = client_instance
      list = []
      if container
        dir = client.service.directories.get container
        if dir
          Log.info "Listing objects in '#{container}'"
          files = dir.files
          files.each do |f|
            fname = f.key
            unless options[:decrypt_filenames]
              list << fname
              Log.info fname
              next
            end
            # Skip segments
            next if fname =~ /\/segments\/\d+\.\d{2}\/\d+\/\d+/ and \
                    not options[:list_segments]

            # Raises exception if the object is a
            # manifest but there are no segments available
            begin 
              metadata = f.metadata
            rescue Fog::Storage::OpenStack::NotFound
              Log.warn "The file #{fname} is an object manifest, but there are no segments"
              Log.warn "available. I won't be able to decrypt the filename."
              Log.info fname
              list << fname
              next
            end
            if metadata[:encrypted_name] 
              fname = decrypt_filename metadata[:encrypted_name], 
                                       @config[:password] + @config[:secure_random]
              Log.info "#{fname.ljust(55)} #{set_color("[encrypted]",:red, :bold)}"
              Log.info "  hash: #{f.key}" if options[:display_hash]
            else
              Log.info fname.ljust(55)
            end
            list << fname
          end 
          list
        else
          raise "Container '#{container}' not found"
        end
      else
        Log.info "Listing containers"
        directories = client.service.directories
        directories = directories.map { |d| Log.info d.key; d.key }
        directories
      end
    end
  end
end


