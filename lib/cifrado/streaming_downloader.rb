require 'net/http'
require 'net/https'

module Cifrado
  class StreamingDownloader

    def self.get url, output, options = {}
      uri = URI.parse url
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      copts = options[:connection_options]
      if copts[:ssl_verify_peer] == false
        Log.warn "Disabling SSL verification"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
      end
      #http.open_timeout = 10 # seconds
      #http.read_timeout = 10 # seconds
      Log.debug "Request URL #{uri.request_uri}"
      request = Net::HTTP::Get.new(uri.request_uri)

      headers = options[:headers]
      request.initialize_http_header headers

      Log.debug "Downloading file to #{output}"

      http.request(request) do |response|
        File.open(output, "wb") do |file|
          response.read_body do |segment|
            if options[:progress_callback]
              options[:progress_callback].call segment.length
            end
            file.write(segment)
          end
        end
      end
    end

  end
end
