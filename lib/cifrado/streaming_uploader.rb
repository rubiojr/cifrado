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
  require 'cifrado/rate_limit'

  class StreamingUploader

    class << self

      def put(to_url, params = {})
        
        file = params[:file]
        headers = params[:headers] || {}
        chunker = nil
        rate_limit = Cifrado::RateLimit.new(params[:bwlimit])

        if file
          headers.merge!({ 'Content-Length' => File.size(file.path).to_s })

          chunker = lambda do
            chunk = file.read(4096).to_s

            rate_limit.upload(chunk.size) if rate_limit

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

