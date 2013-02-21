module Cifrado 

  # StreamingUploader Adapted by Sergio Rubio <rubiojr@frameos.org>
  #
  # inspired by Opscode Chef StreamingCookbookUploader chef/streaming_cookbook_uploader.rb
  # http://opscode.com
  # 
  # inspired by/cargo-culted from http://stanislavvitvitskiy.blogspot.com/2008/12/multipart-post-in-ruby.html
  # On Apr 6, 2010, at 3:00 PM, Stanislav Vitvitskiy wrote:
  #
  # It's free to use / modify / distribute. No need to mention anything. Just copy/paste and use.
  #
  # Regards,
  # Stan


  require 'net/http'
  require 'net/https'

  class StreamingUploader

    class << self

      def put(to_url, params = {}, &block)
        parts = []
        content_file = nil
        
        params.each do |key, value|
          if value.kind_of?(File)
            filepath = value.path
            parts << StreamPart.new(value, File.size(filepath))
          end
        end
        
        url = URI.parse(to_url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if url.scheme == "https"
        
        if params[:ssl_verify_peer] == false
          Log.debug "Uploading file with SSL verification DISABLED"
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
        end

        if RUBY_VERSION =~ /^1\./
          body_stream = MultipartStream.new(parts, block, params[:bwlimit])
        else # Assumed >= 2.0
          body_stream = MultipartStreamV2.new(parts, block)
        end
        
        headers = { 'Content-Length' => body_stream.size.to_s }
        headers = headers.merge(params[:headers]) if params[:headers]

        req = Net::HTTP::Put.new("#{url.path}?#{url.query}", headers)
        Log.debug "HEADERS: " + headers.inspect
        Log.debug "HOST:    " + url.host 
        Log.debug "PORT:    " + url.port.to_s
        Log.debug "PATH:    " + url.path
        Log.debug "URL:     " + url.to_s
        
        req.content_length = body_stream.size
        #req.content_type = i
        req.body_stream = body_stream
        
        if params[:timeout] == -1
          http.read_timeout = nil 
        elsif params[:timeout]
          http.read_timeout = params[:timeout]
        else
          # Use default timeout
        end
        Log.debug "HTTP PUT request"
        res = http.request(req)
        res
      end
      
    end

    class StreamPart
      def initialize(stream, size)
        @stream, @size = stream, size
      end

      def size
        @size
      end

      # read the specified amount from the stream
      def read(offset, how_much)
        @stream.read(how_much)
      end
    end

    class StringPart
      def initialize(str)
        @str = str
      end
      
      def size
        @str.length
      end

      # read the specified amount from the string startiung at the offset
      def read(offset, how_much)
        @str[offset, how_much]
      end
    end

    class MultipartStream
      def initialize(parts, blk = nil, bwlimit = 0)
        @callback = nil
        if blk
          @callback = blk
        end
        @parts = parts
        @part_no = 0
        @part_offset = 0
        @bwlimit = bwlimit || 0
        @sleep_counter = 0.01
        @read = 0
      end
      
      def size
        @parts.inject(0) {|size, part| size + part.size}
      end
      
      # breaks in ruby 2.0
      # Use MultipartStreamV2
      def read(how_much)
        if @bwlimit > 0
          @time = Time.now.to_f unless @time
          bps = @read/(Time.now.to_f - @time)
          if bps > @bwlimit
            sleep @sleep_counter
            @sleep_counter += 0.01
          else
            @sleep_counter -= 0.01 if @sleep_counter >= 0.02
          end
          @read += how_much
        end

        @callback.call(how_much) if @callback
        return nil if @part_no >= @parts.size

        how_much_current_part = @parts[@part_no].size - @part_offset
        
        how_much_current_part = if how_much_current_part > how_much
                                  how_much
                                else
                                  how_much_current_part
                                end
        
        how_much_next_part = how_much - how_much_current_part

        current_part = @parts[@part_no].read(@part_offset, how_much_current_part)
        
        # recurse into the next part if the current one was not large enough
        if how_much_next_part > 0
          @part_no += 1
          @part_offset = 0
          next_part = read(how_much_next_part)
          current_part + if next_part
                           next_part
                         else
                           ''
                         end
        else
          @part_offset += how_much_current_part
          current_part
        end
      end
    end
    
    # Ruby 2.0
    class MultipartStreamV2
      def initialize(parts, blk = nil)
        @callback = nil
        if blk
          @callback = blk
        end
        @parts = parts
        @part_no = 0
        @part_offset = 0
      end
      
      def size
        @parts.inject(0) {|size, part| size + part.size}
      end
      
      # breaks in ruby 2.0
      # Use MultipartStreamV2
      def read(how_much)
        @callback.call(how_much) if @callback
        return nil if @part_no >= @parts.size

        how_much_current_part = @parts[@part_no].size - @part_offset
        
        how_much_current_part = if how_much_current_part > how_much
                                  how_much
                                else
                                  how_much_current_part
                                end
        
        how_much_next_part = how_much - how_much_current_part

        current_part = @parts[@part_no].read(@part_offset, how_much_current_part)
        
        # recurse into the next part if the current one was not large enough
        if how_much_next_part > 0
          @part_no += 1
          @part_offset = 0
          next_part = read(how_much_next_part)
          current_part + if next_part
                           next_part
                         else
                           ''
                         end
        else
          @part_offset += how_much_current_part
          current_part
        end
      end
    end
    
  end
end

