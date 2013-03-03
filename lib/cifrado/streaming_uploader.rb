module Cifrado 

  require 'net/http'
  require 'net/https'
  require 'cifrado/rate_limit'

  class StreamingUploader

    class << self

      def put(to_url, params = {})
        
        file = params[:file]
        headers = params[:headers] || {}
        chunker = nil
        rate_limit = nil
        rate_limit = Cifrado::RateLimit.new(params[:bwlimit]) if params[:bwlimit]

        if file
          headers.merge!({ 'Content-Length' => File.size(file.path).to_s })

          chunker = lambda do
            chunk = file.read(4096).to_s

            rate_limit.limit(chunk.size) if rate_limit

            if block_given? and chunk.size > 0
              yield chunk.size
            end
            chunk
          end
        end

        Excon.put to_url,
                  :headers => headers, 
                  :request_block => chunker
      end

    end
  end

end

