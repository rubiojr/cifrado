module Cifrado::Plugins
  class PluginManager < Cifrado::Plugin
    namespace 'plugin'

    desc 'install URL', 'Install a new plugin'
    def install
      puts 'Installing plugin'
    end
  end
end
