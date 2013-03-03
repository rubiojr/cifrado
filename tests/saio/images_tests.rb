Shindo.tests('Cifrado | CLI#saio') do

  tests '#images' do
    test 'list' do
      Cifrado::Plugins::Saio.class_options[:api_key] = \
        Thor::Option.parse :api_key, fog_settings[:digitalocean_api_key]
      Cifrado::Plugins::Saio.class_options[:client_id] = \
        Thor::Option.parse :client_id, fog_settings[:digitalocean_client_id]
      cli = Cifrado::Plugins::Saio.new 
      cli.images.size > 0
    end
  end

end
