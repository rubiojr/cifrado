require 'singleton'

module Cifrado
  class Config
    include Singleton
    
    def initialize
      unless File.directory?(cache_dir)
        Log.debug "Creating cache dir: #{cache_dir}"
        FileUtils.mkdir_p(cache_dir) 
      end
    end

    def cache_dir
      File.join(ENV['HOME'], '.cache/cifrado')
    end
    
    def config_dir=(dir)
      @config_dir = dir
    end

    def config_dir
      @config_dir || File.join(ENV['HOME'], '.config/cifrado')
    end
  end
end
