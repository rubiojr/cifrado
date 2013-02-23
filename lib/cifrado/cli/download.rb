module Cifrado
  class CLI
    desc "download [CONTAINER] [OBJECT]", "Download container, objects"
    option :decrypt, :type => :boolean
    option :passphrase, :type => :string, :desc => "Passphrase used to decrypt the file"
    option :output
    option :progressbar, :default => :fancy
    option :bwlimit, :type => :numeric
    def download(container, object = nil)
      client = client_instance
      files = []
      if object
        files << object
      else
        Log.info "Downloading files from container #{container}"
        dir = client.service.directories.get(container)
        files = dir.files if dir
      end
      pb = Progressbar.new 1, 1, :style => options[:progressbar]
      found = nil
      files.each do |f|
        obj = f.is_a?(String) ? f : f.key
        if !f.is_a?(String) and f.metadata[:encrypted_name]
          fname = decrypt_filename f.metadata[:encrypted_name], @config[:password]
          Log.info "Downloading file #{fname}"
        else
          Log.info "Downloading file #{obj}"
        end
        if client.file_available?(container, obj)
          r = client.download container, obj,
                              :decrypt => options[:decrypt],
                              :passphrase => options[:passphrase],
                              :output => options[:output],
                              :progress_callback => pb.block,
                              :bwlimit => bwlimit
          found = true 
        else 
          Log.debug 'Trying to find hashed object name'
          file_hash = (Digest::SHA2.new << obj).to_s
          r = client.download container, file_hash,
                              :decrypt => options[:decrypt],
                              :passphrase => options[:passphrase],
                              :output => options[:output],
                              :progress_callback => pb.block,
                              :bwlimit => bwlimit
          found = true if r.status == 200
        end
      end
      unless found
        raise "File #{object} not found in #{container}"
      end
      found
    end
  end
end
