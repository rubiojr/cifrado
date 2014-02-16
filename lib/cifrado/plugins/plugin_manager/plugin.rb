require_relative 'list'
require_relative 'install'
require_relative 'remove'

module Cifrado
  class CLI
    desc 'plugin SUBCOMMAND ...ARGS', 'Manage cifrado plugins'
    subcommand 'plugin', Cifrado::Plugins::PluginManager
  end
end
