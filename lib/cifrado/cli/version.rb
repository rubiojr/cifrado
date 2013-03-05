module Cifrado
  class CLI
    desc 'version', 'Print Cifrado version'
    def version
      Log.info Cifrado::VERSION
    end
  end
end
