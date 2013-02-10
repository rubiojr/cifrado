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
  end
end
