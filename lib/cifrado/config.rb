require 'singleton'

module Cifrado
  class Config
    include Singleton
    
    def init_env
      Log.debug "Creating cache dir: #{cache_dir}"
      FileUtils.mkdir_p(cache_dir) 
      Log.debug "Creating config dir: #{config_dir}"
      FileUtils.mkdir_p(config_dir) 
    end

    def cache_dir=(dir)
      @cache_dir = dir
    end

    def cache_dir
      @cache_dir ||= File.join(ENV['HOME'], '.cache/cifrado')
    end
    
    def config_dir=(dir)
      @config_dir = dir
    end

    def config_dir
      @config_dir ||= File.join(ENV['HOME'], '.config/cifrado')
    end
  end
end
