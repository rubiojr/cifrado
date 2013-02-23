module Cifrado
  class CLI
    desc "set-acl CONTAINER", 'Set an ACL on containers and objects'
    option :acl, :type => :string, :required => true
    def set_acl(container, object = nil)
      client = client_instance
      client.set_acl options[:acl], container
    end
  end
end
