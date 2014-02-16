module Cifrado::Plugins
  class PluginManager < Cifrado::Plugin
    namespace 'plugin'

    desc 'remove NAME', 'Remove/Disable a plugin'
    def remove 
      puts 'Removing a plugin'
    end
  end
end
