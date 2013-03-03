Shindo.tests('Cifrado | CLI#saio', ['expensive']) do

  tests '#bootstrap' do

    Cifrado::Plugins::Saio.class_options[:api_key] = \
      Thor::Option.parse :api_key, fog_settings[:digitalocean_api_key]
    Cifrado::Plugins::Saio.class_options[:client_id] = \
      Thor::Option.parse :client_id, fog_settings[:digitalocean_client_id]
    cli = Cifrado::Plugins::Saio.new 

    test '512MB image' do
      #
      # FIXME: find a way to test default options
      #
      cli.options = {
        :client_id => fog_settings[:digitalocean_client_id],
        :api_key => fog_settings[:digitalocean_api_key],
        :ssh_key_name => 'personal',
        :server_name => 'cifrado-saio-tests',
        :flavor => '512MB',
        :region => 'New York 1',
        :image  => 'Ubuntu 12.04 x64 Server',
        :disk_size => 15,
      }.merge(cli.options)
      @server = cli.bootstrap
      !(cli.service.servers.find { |s| s.name == @server.name }).nil?
    end

    test 'destroy server' do
      @server.destroy.status == 200
    end

  end

end
