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
        Log.debug "Downloading file with SSL verification DISABLED"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
      end
      #http.open_timeout = 10 # seconds
      #http.read_timeout = 10 # seconds
      Log.debug "Request URL #{uri.request_uri}"
      request = Net::HTTP::Get.new(uri.request_uri)

      headers = options[:headers]
      request.initialize_http_header headers

      Log.debug "Downloading file to #{output}"
      
      bwlimit = options[:bwlimit] || 0
      sleep_counter = 0.01
      @read = 0
      time = Time.now.to_f 

      http.request(request) do |response|
        clength = response['Content-Length'].to_i
        File.open(output, "wb") do |file|
          response.read_body do |segment|
            if bwlimit > 0
              bps = @read/(Time.now.to_f - time)
              if (bps > bwlimit) 
                sleep sleep_counter
                sleep_counter += 0.01
              else
                sleep_counter -= 0.01 if sleep_counter >= 0.02
              end
              @read += segment.length
            end
            if options[:progress_callback]
              options[:progress_callback].call clength, segment.length
            end
            file.write(segment)
          end
        end
      end
    end

  end
end
