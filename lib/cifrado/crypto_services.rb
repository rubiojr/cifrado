module Cifrado
  class CryptoServices

    def initialize
      require 'shellwords'
    end

    def encrypt(file, output, options = {})
      Log.debug "Encrypting file #{file}..."
      recipient = options[:recipient]
      cmd = "/usr/bin/gpg --yes --no-encrypt-to --no-default-recipient --recipient '#{recipient}' --output #{Shellwords.escape(output)} --encrypt #{Shellwords.escape(file)}"
      Log.debug "Encrypting with: #{cmd}"
      out = `#{cmd} 2>&1`
      if $? != 0
        Log.debug "Failed to encrypt chunk #{file}"
      else
        if options[:delete_source]
          File.delete file 
          Log.debug "Deleting unencrypted chunk #{file}"
        end
      end
      Log.debug out
      output
    end

    def self.encrypted?(file)
      !`/usr/bin/file #{Shellwords.escape(file)}`.match(/GPG encrypted/).nil?
    end

  end
end
