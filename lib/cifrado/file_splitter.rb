require 'digest/md5'

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
      @source = filename
      @file = File.new(filename, "rb")
      @chunk_number = chunk_number || calculate_chunks(filename)
      
      # when we are splitting a file into a given number of chunks, 
      # the last chunk could be bigger than the others
      @each_size, @extra = File.size(filename).divmod(@chunk_number)
      @cache_dir = File.expand_path cache_dir
      @chunk_suffix = "/segments/#{'%.2f' % Time.now.to_f}/#{File.size(filename)}/"
    end

    def reused_chunks?
      @reused_chunks || false
    end

    def clean_cache
      Dir["#{@cache_dir}/*md5"].each { |f| Log.debug "Deleting #{f}"; File.delete f }
      Dir["#{@cache_dir}/*-chunk-*"].each { |f| Log.debug "Deleting #{f}"; File.delete f }
      Dir["#{@cache_dir}/*-segment-*"].each { |f| Log.debug "Deleting #{f}"; File.delete f }
    end
    
    def split
      # create cache directory
      unless File.directory?(@cache_dir)
        Log.debug "Creating cache dir: #{@cache_dir}"
        FileUtils.mkdir_p(@cache_dir) 
      end

      # Try to re-use previous chunks if found
      md5sum_path = "#{File.join(@cache_dir, @filename)}.md5"
      if File.exist?(md5sum_path)
        Log.debug "md5sum file found: #{md5sum_path}. Trying to re-use file chunks"
        hashes = File.readlines(md5sum_path)
        object_hash = hashes.delete_at 0
        prev_chunks = []
        reusable = 0
        hashes.each do |l|
          file, hash = l.split(':').map { |t| t.strip.chomp }
          file = File.join(@cache_dir, file)
          if File.exist?(file) and Digest::MD5.file(file).hexdigest == hash
            Log.debug "Chunk #{file} can be re-used"
            reusable += 1
            prev_chunks << file
          end
        end
        if (prev_chunks.size == reusable) and \
           reusable != 0 and \
           prev_chunks.size == @chunk_number
          Log.debug "All the previous chunks present"
          @reused_chunks = true
          prev_chunks.each { |c| yield c if block_given? }
          return prev_chunks
        end
      end

      # Cached chunks not found or not valid
      Log.debug "Create md5sum before splitting: #{md5sum_path}"
      md5sum = File.open md5sum_path, 'w+'
      md5sum.puts "#{File.basename(@source)}:#{Digest::MD5.file(@source).hexdigest}"

      chunks = []
      Log.debug "Splitting file #{@filename} in #{@chunk_number} chunks"
      Log.debug "Destination directory: #{@cache_dir}"
      (1..@chunk_number).each do |n|
        chunk = File.join(@cache_dir, @filename + "#{@chunk_suffix.gsub('/','-')}#{n}")
        Log.debug "Writing chunk #{chunk}"
        File.open(chunk, "wb") do |f|
          f << @file.read(@each_size)
          if n == @chunk_number and not @extra.nil?
            f << @file.read(@extra)
          end
        end
        chunks << chunk
        Log.debug "Hashing chunk #{chunk}"
        md5sum.puts "#{File.basename(chunk)}:#{Digest::MD5.file(chunk).hexdigest}"
        yield chunk if block_given?
      end
      md5sum.close
      chunks
    end

  end

end
