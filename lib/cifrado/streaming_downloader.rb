require 'net/http'
require 'net/https'

module Cifrado
  class StreamingDownloader

    def self.get url, output, options = {}
      if output.nil? and !options[:stream]
        raise ArgumentError.new('Invalid output file')
      end
      uri = URI.parse url
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      copts = options[:connection_options]
      if copts[:ssl_verify_peer] == false
        Log.debug "SSL verification DISABLED"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
      end
      #http.open_timeout = 10 # seconds
      #http.read_timeout = 10 # seconds
      Log.debug "Request URL #{uri.request_uri}"
      request = Net::HTTP::Get.new(uri.request_uri)

      headers = options[:headers]
      request.initialize_http_header headers

      rate_limit = nil
      rate_limit = Cifrado::RateLimit.new(options[:bwlimit]) if options[:bwlimit]

      unless options[:stream]
        file = File.open(output, "wb") 
        Log.debug "Downloading file to #{output}"
      end
      callback = options[:progress_callback]

      http.request(request) do |response|
        clength = response['Content-Length'].to_i
        response.read_body do |segment|
          rate_limit.limit(segment.size) if rate_limit
          callback.call(clength, segment.length, segment) if callback
          file.write(segment) if file
        end
      end
    ensure
      file.close if file
    end

  end
end
