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

      def put(to_url, params = {})
        
        file = params[:file]
        if file
          headers = { 'Content-Length' => File.size(file.path).to_s }

          chunker = lambda do
            chunk = file.read(Excon.defaults[:chunk_size]).to_s
            if block_given? and chunk.size > 0
              yield chunk.size
            end
            chunk
          end

          headers = headers.merge(params[:headers]) if params[:headers]
          Excon.put to_url,
                    :headers => headers, 
                    :request_block => chunker
        else
          headers ={}
          headers.merge(params[:headers]) if params[:headers]
          Excon.put to_url,
                    :headers => headers
        end


      end
      
    end
  end

end

