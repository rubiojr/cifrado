module Cifrado
  class CryptoServices

    def encrypt(file, output, options = {})
      Log.debug "Encrypting file #{file}..."
      recipient = options[:recipient]
      out = `/usr/bin/gpg --yes --recipient #{recipient} --output #{output} --encrypt #{file} 2>&1`
      if $? != 0
        Log.debug "Failed to encrypt chunk #{file}"
        Log.debug out
      else
        if options[:delete_source]
          File.delete file 
          Log.debug "Deleting unencrypted chunk #{file}"
        end
      end
      output
    end

    def self.encrypted?(file)
      !`file #{file}`.match(/GPG encrypted/).nil?
    end

  end
end
