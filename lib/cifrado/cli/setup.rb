module Cifrado
  class CLI
    desc "setup", "Initial Cifrado configuration"
    def setup
      config_file = File.join(ENV['HOME'], '.cifradorc')
      if File.exist?(config_file)
        Log.warn "Config file #{set_color config_file, :bold} already exist."
        Log.warn "IMPORTANT: Make sure you backup the current config"
        Log.warn "before saving a new configuration."
        unless yes? "Continue?"
          return
        end
        config = YAML.load_file(config_file)
      else
        config = {}
      end


      puts "Running cifrado setup..."
      puts "Please provide OpenStack/Rackspace credentials."
      puts
      puts "Cifrado can save this settings in #{ENV['HOME']}/.cifradorc"
      puts "for later use."
      puts "The settings (password included) are saved unencrypted."
      puts
      config[:username] = ask(set_color('Username:', :bold))
      config[:tenant]   = ask(set_color('Tenant:', :bold))
      system 'stty -echo'
      config[:password] = ask(set_color 'Password:', :bold)
      system 'stty echo'
      puts
      config[:auth_url] = ask(set_color 'Auth URL:', :bold)

      if !config[:secure_random]
        config[:secure_random] = SecureRandom.hex
      end

      if yes? "Do you want to save these settings?"
        if File.exist?(config_file)
          backup = "#{config_file}.bak.#{Time.now.to_i}"
          FileUtils.cp config_file, backup
          Log.info "Saving backup file to #{backup}."
        end
        File.open(config_file, 'w') do |f| 
          f.puts config.to_yaml
          f.chmod 0600
        end
        @settings_saved = true
      end

      Log.debug "Setup done"
      config
    end
  end
end
