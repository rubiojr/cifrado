module Cifrado

  # http://rubyforge.org/snippet/download.php?type=snippet&id=146
  # Splits a file (eg. abc.ext) to a number of smaller files (eg. abc.ext.chunk1, abc.ext.chunk2 etc)
  # Does not do any error handling
  # Expects file to be split to exist in the current directory!
  #
  #
  class FileSplitter

    # FileSplitter.new("elfari.webm", 10).split
    #
    # @param [String] file path to split
    # @param [Integer] number of chunks
    # @param [String] Destination directory of the chunks
    def initialize(filename, chunk_number, dest_dir = ".")
      @filename = File.basename filename
      @file = File.new(filename, "rb")
      @chunk_number = chunk_number
      @dest_dir = File.expand_path dest_dir
      
      # when we are splitting a file into a given number of chunks, 
      # the last chunk could be bigger than the others
      @each_size, @extra = File.size(filename).divmod(@chunk_number)
    end
    
    def split(options = {})
      Log.debug "Splitting file #{@filename} in #{@chunk_number} chunks"
      Log.debug "Destination directory: #{@dest_dir}"
      (1..@chunk_number).each do |n|
        if options[:encryption]
          unencrypted = File.join(@dest_dir, @filename + "-chunk-#{n}.tmp")
        else
          unencrypted = File.join(@dest_dir, @filename + "-chunk-#{n}")
        end
        Log.debug "Writing chunk #{unencrypted}"
        File.open(unencrypted, "w+b") do |f|
          f << @file.read(@each_size)
          if n == @chunk_number and not @extra.nil?
            f << @file.read(@extra)
          end
        end
        if options[:encryption]
          Log.debug "Encrypting chunk #{unencrypted}"
          etype = options[:encryption_type]
          erecip = options[:encryption_recipient]
          encrypted = File.join(@dest_dir, @filename + "-chunk-#{n}")
          out = `/usr/bin/gpg --yes --recipient #{erecip} --output #{encrypted} --encrypt #{unencrypted}`
          if $? != 0
            Log.error "Failed to encrypt chunk #{unencrypted}"
          end
        end
      end
    end

  end

end
