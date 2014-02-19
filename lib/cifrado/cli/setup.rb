module Cifrado
  class CLI
    desc "setup", "Initial Cifrado configuration"
    def setup
      config_instance = Cifrado::Config.instance
      config_file = File.join(config_instance.config_dir, 'cifradorc')
      unless File.directory?(config_instance.config_dir)
        FileUtils.mkdir_p config_instance.config_dir
      end
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
      puts "Please provide OpenStack/Rackspace/HPCloud credentials."
      puts
      puts "Cifrado can save these settings in #{config_file}"
      puts "for later use."
      puts "The settings (password included) are saved unencrypted."
      puts
      config[:username] = ask(set_color('Username:', :bold))
      system 'stty -echo'
      config[:password] = ask(set_color 'Password:', :bold)
      system 'stty echo'
      puts
      config[:auth_url] = ask(set_color 'Auth URL:', :bold)
      if config[:auth_url] !~ /rackspacecloud\.com/
        config[:tenant]   = ask(set_color('Tenant:', :bold))
      end

      if !config[:secure_random]
        # shit happens
        if RUBY_VERSION >= '1.9'
          config[:secure_random] = SecureRandom.hex.encode('UTF-8')
        else
          config[:secure_random] = SecureRandom.hex
        end
      end

      if yes? "Do you want to save these settings? (y/n) "
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
        Log.info "Saved!"
      end

      Log.debug "Setup done"
      config
    end
  end
end
