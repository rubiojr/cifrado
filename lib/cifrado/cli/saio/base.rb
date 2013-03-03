module Cifrado
  module Plugins
    class Saio < Thor
      include Cifrado::Utils

      class_option :provider,     :type => :string
      class_option :api_key,      :type => :string, :required => true
      class_option :client_id,    :type => :string, :required => true

      no_tasks do
        def service
          return @service if @service
          client_id = options[:client_id]
          api_key   = options[:api_key]
          @service = Fog::Compute.new :provider => 'DigitalOcean',
                                      :digitalocean_api_key   => api_key,
                                      :digitalocean_client_id => client_id
        end
      end

    end
  end
end
