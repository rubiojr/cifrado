module Cifrado

  # http://rubyforge.org/snippet/download.php?type=snippet&id=146
  # Splits a file (eg. abc.ext) to a number of smaller files (eg. abc.ext.chunk1, abc.ext.chunk2 etc)
  # Does not do any error handling
  # Expects file to be split to exist in the current directory!
  #
  #
  class FileSplitter
    include Utils

    attr_reader :cache_dir
    attr_accessor :chunk_suffix

    # FileSplitter.new("elfari.webm", 10).split
    #
    # @param [String] file path to split
    # @param [Integer] number of chunks
    # @param [String] Destination directory of the chunks
    def initialize(filename, 
                   chunk_number = nil, 
                   cache_dir = File.join(ENV['HOME'], '.cache/cifrado') )
      @filename = File.basename filename
      @file = File.new(filename, "rb")
      @chunk_number = chunk_number || calculate_chunks(filename)
      
      # when we are splitting a file into a given number of chunks, 
      # the last chunk could be bigger than the others
      @each_size, @extra = File.size(filename).divmod(@chunk_number)
      @cache_dir = File.expand_path cache_dir
      @chunk_suffix = '-chunk-'
    end
    
    def split(options = {})
      @tmp_cache = File.join(@cache_dir, Time.now.to_f.to_s)
      # Processor should be a proc responding to .call
      processor = options[:processor]
      # create cache directory
      unless File.directory?(@cache_dir)
        Log.debug "Creating cache dir: #{@cache_dir}"
        FileUtils.mkdir_p(@cache_dir) 
      end
      Log.debug "Creating tmp cache dir: #{@tmp_cache}"
      FileUtils.mkdir_p(@tmp_cache)
      Log.debug "Cache directory #{@tmp_cache}"

      chunks = []
      Log.debug "Splitting file #{@filename} in #{@chunk_number} chunks"
      Log.debug "Destination directory: #{@cache_dir}"
      (1..@chunk_number).each do |n|
        chunk = File.join(@cache_dir, @filename + "#{@chunk_suffix}#{n}")
        Log.debug "Writing chunk #{chunk}"
        File.open(chunk, "wb") do |f|
          f << @file.read(@each_size)
          if n == @chunk_number and not @extra.nil?
            f << @file.read(@extra)
          end
        end
        if processor
          processor.call chunk
        end
        chunks << chunk
        yield chunk if block_given?
      end
      chunks
    end

  end

end
