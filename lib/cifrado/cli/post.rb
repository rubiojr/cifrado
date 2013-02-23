module Cifrado
  class CLI
    desc "post CONTAINER [DESCRIPTION]", "Create a container"
    def post(container, description = '')
      client = client_instance
      client.service.directories.create :key => container, 
                                        :description => description
    end
  end
end
