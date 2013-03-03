module Cifrado
  class Saio < Thor
    
    desc 'bootstrap', 'Bootstrap a Swift All-In-One installation'
    option :server_name,     :type => :string, :default => 'cifrado-saio'
    option :ssh_key_name,    :type => :string, :required => true
    option :save_settings,   :type => :boolean
    option :bootstrap_debug, :type => :boolean
    option :disk_size, 
           :type => :numeric,
           :default => 15,
           :desc => 'Virtual disk size for Swift (in GB)'
    option :flavor,          
           :type => :string,
           :desc => 'Flavor name to use when bootstraping',
           :default => '51MB'
    option :image,          
           :type => :string,
           :desc => 'Image name to use when bootstraping',
           :default => 'Ubuntu 12.04 x64 Server'
    option :region,          
           :type => :string,
           :desc => 'Region name to use when bootstraping',
           :default => 'New York 1'
    def bootstrap
      require 'shexy'

      Log.level = Logger::DEBUG if options[:bootstrap_debug]

      begin
        available_keys = service.list_ssh_keys.body['ssh_keys']
        key = available_keys.find { |k| k['name'] == options[:ssh_key_name] }
        unless key 
          raise "SSH key #{options[:ssh_key_name]} not available."
        end

        server_name = options[:server_name]
        server = service.servers.find { |s| s.name == server_name }
        if server
          raise "Server #{server_name} is currently running."
        end

        flavor = service.flavors.find { |f| f.name == options[:flavor] }
        image = service.images.find { |i| i.name == options[:image] }
        region = service.regions.find { |r| r.name == options[:region] }

        unless image and flavor and region
          raise "The specified image, flavor or region was not found"
        end

        Log.info "Creating server #{server_name}..."
        server = service.servers.create :name        => options[:server_name],
                                        :image_id    => image.id,
                                        :flavor_id   => flavor.id,
                                        :region_id   => region.id,
                                        :ssh_key_ids => key['id']
        Log.info "Server provisioned, waiting for IP..."
        server.wait_for(120) { ip_address }
        Log.info "Server IP: #{server.ip_address}"

        #
        # Copy the provisioning script to the server
        #
        Shexy.host = server.ip_address
        Shexy.user = 'root'
        Shexy.flags = { :paranoid => false }
        Log.info 'Waiting for SSH...'
        Shexy.wait_for_ssh(90)
        Log.info 'Bootstraping Swift All-In-One (this may take a while)...'

        if RUBY_VERSION >= '1.9'
          secure_random = SecureRandom.hex.encode('UTF-8')
          user_password = SecureRandom.hex.encode('UTF-8')
        else
          user_password = SecureRandom.hex
          secure_random = SecureRandom.hex
        end
      
        script = bootstrap_script(user_password, options[:disk_size])
        Shexy.copy_to script, '/root/saio.sh'

        # Provision Swift+Keystone
        Shexy.exe '/bin/bash /root/saio.sh' do |out, err|
          out.each_line { |l| Log.debug l } 
        end

        config = {
          :auth_url => "https://#{server.ip_address}:5000/v2.0/tokens",
          :username => 'admin',
          :tenant   => 'admin',
          :password => user_password,
          :secure_random => secure_random
        }

        # Provisioning finished, print details
        Log.info
        Log.info 'Swift is ready. Login details:'
        Log.info
        Log.info "---"
        Log.info ":auth_url:      https://#{server.ip_address}:5000/v2.0/tokens"
        Log.info ":username:      admin"
        Log.info ":tenant:        admin"
        Log.info ":password:      #{user_password}"
        Log.info ":secure_random: #{secure_random}"
        Log.info

        save_settings(config) if options[:save_settings]
      rescue Excon::Errors::Found => e
        raise "Authentication failed"
      end
    end

    private
    def save_settings(config)
      config_file = File.join(ENV['HOME'], '.config/cifrado/cifradorc')
      FileUtils.mkdir_p File.join(ENV['HOME'], '.config/cifrado')
      if File.exist?(config_file)
        raise 'Cifrado config file exists. Refusing to overwrite.'
      else
        Log.info "Saving settings to #{config_file} as requested."
        File.open config_file, 'w' do |f|
          f.puts config.to_yaml
        end
      end
    end

    def bootstrap_script(password, disk_size = 15)
      require 'erb'
      template = File.join(File.dirname(__FILE__), 'scripts/saio.sh.erb')
      result = ERB.new(File.read(template)).result(binding)
      tmpfile = "/tmp/#{SecureRandom.hex}"
      File.open tmpfile, 'w' do |f|
        f.puts result
      end
      tmpfile
    end

  end
end

