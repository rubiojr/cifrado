require 'digest/sha1'

module Cifrado
  module Utils

    def prettify_backtrace(e)
      Log.debug e.backtrace.join("\nDEBUG: ")
    end

    def mime_type(file)
      mime = `/usr/bin/file -b --mime-type #{Shellwords.escape(file)} 2>/dev/null`.strip.chomp
      mime.empty? ? nil : mime
    end

    def clean_object_name(obj)
      Pathname.new(obj.gsub(/^(\/+|.\/)/,'')).cleanpath.to_s
    end

    def unix_time(secs)
      (Time.at secs.to_i).to_s
    end

    def decrypt_filename(name, password, options = {})
      cipher = CryptoEngineAES.new password
      cipher.decrypt name
    end

    def encrypt_filename(name, password, options = {})
      cipher = CryptoEngineAES.new password
      cipher.encrypt name
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
