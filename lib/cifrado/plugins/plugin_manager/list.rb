module Cifrado::Plugins
  class PluginManager < Cifrado::Plugin
    namespace 'plugin'

    desc 'list', 'List installed plugins'
    def list
      puts 'listing plugins'
    end
  end
end
