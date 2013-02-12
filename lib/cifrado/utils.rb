require 'digest/sha1'

module Cifrado
  module Utils

    def unix_time(secs)
      (Time.at secs.to_i).to_s
    end

    def encrypt_filename(name, options = {})
      tokens = options[:encrypt].split(':')
      etype = tokens.first
      s = CryptoServices.new
      if etype == 'a'
        recipient = tokens[1..-1].join(':')
        out = s.encrypt name, "#{obj}.encrypted", 
                        :type => :asymmetric,
                        :recipient => recipient
        Digest::SHA1.hexdigest out
      elsif etype == 's'
        passphrase = tokens[1..-1].join(':')
        out = s.encrypt obj, "#{obj}.encrypted", 
                        :type => :symmetric,
                        :passphrase => passphrase
      else
        raise "Invalid encryption type #{etype}."
      end
    end

    def humanize_bytes(bytes)
      m = bytes.to_i
      units = %w[Bytes KB MB GB TB PB]
      while (m/1024.0) >= 1
        m = m/1024.0
        units.shift
      end
      return "%.2f #{units[0]}" % m
    end

    def calculate_chunks(file)
      # File size in bytes
      size = File.size(file)
      if size >= 1 and size <= 10485760
        1
      # if file >= 20MB and <= 50MB, split in chunks of 10MB
      elsif size > 10485760 and size <= 104857600
        size/10485760
      # split in chunk of 100 MB
      else
        size/104857600
      end
    end

  end
end
