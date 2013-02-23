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
            unless options[:decrypt_filenames]
              list << f.key
              puts f.key
              next
            end
            # Skip segments
            next if f.key =~ /\/segments\/\d+\.\d{2}\/\d+\/\d+/ and \
                    not options[:list_segments]

            metadata = f.metadata
            if metadata[:encrypted_name] 
              fname = decrypt_filename metadata[:encrypted_name], 
                                       @config[:password] + @config[:secure_random]
              puts "#{fname.ljust(55)} #{set_color("[encrypted]",:red, :bold)}"
              puts "  hash: #{f.key}" if options[:display_hash]
            else
              puts f.key.ljust(55)
            end
            list << f.key
          end 
          list
        else
          raise "Container '#{container}' not found"
        end
      else
        Log.info "Listing containers"
        directories = client.service.directories
        directories.each { |d| puts d.key }
        directories
      end
    end
  end
end


