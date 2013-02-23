module Cifrado
  class CLI 
    desc "stat [CONTAINER] [OBJECT]", "Displays information for the account, container, or object."
    def stat(container = nil, object = nil)
      client = client_instance
      creds = client.service.credentials
      mgmt_url = creds[:server_management_url]
      
      reject_headers = ['Accept-Ranges', 'X-Trans-Id']
      unless container and object
        reject_headers << 'Content-Length'
      end
      reject_headers << 'Content-Type' unless object

      object = clean_object_name(object) if object
      headers = client.head(container, object)
      if headers
        puts "Account:".ljust(30) + File.basename(URI.parse(mgmt_url).path)
        headers.sort.each do |k, v| 
          next if reject_headers.include?(k)
          if k == 'X-Timestamp'
            puts "#{(k + ":").ljust(30)}#{v} (#{unix_time(v)})" 
          elsif k == 'X-Account-Bytes-Used' or k == 'Content-Length'
            puts "#{(k + ":").ljust(30)}#{v} (#{humanize_bytes(v)})" 
          elsif k == 'X-Object-Meta-Encrypted-Name'
            puts "#{(k + ":").ljust(30)}#{v}"
          else
            puts "#{(k + ":").ljust(30)}#{v}" 
          end
        end
      else
        if object
          raise "Object not found."
        else
          raise "Container not found."
        end
      end
      headers
    end
  end
end
