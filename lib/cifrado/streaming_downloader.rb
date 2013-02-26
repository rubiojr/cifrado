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

      bwlimit = options[:bwlimit] || 0
      sleep_counter = 0.01
      read = 0
      time = Time.now.to_f 
      unless options[:stream]
        file = File.open(output, "wb") 
        Log.debug "Downloading file to #{output}"
      end
      callback = options[:progress_callback]

      http.request(request) do |response|
        clength = response['Content-Length'].to_i
        response.read_body do |segment|
          if bwlimit > 0
            bps = read/(Time.now.to_f - time)
            if (bps > bwlimit) 
              sleep sleep_counter
              sleep_counter += 0.01
            else
              sleep_counter -= 0.01 if sleep_counter >= 0.02
            end
            read += segment.length
          end
          callback.call(clength, segment.length, segment) if callback
          file.write(segment) if file
        end
      end
    ensure
      file.close if file
    end

  end
end
