module Cifrado
  class Plugin < Thor

    # Plugins will be loaded from this directories in the order listed
    # here.
    #
    # ~/.local/cifrado/plugins
    # /etc/cifrado/plugins
    # /usr/local/etc/cifrado/plugins
    #
    PLUGIN_HOME = [
      File.expand_path("~/.local/cifrado/plugins"),
      "/etc/cifrado/plugins",
      "/usr/local/etc/cifrado/plugins",
      "#{File.join(File.dirname(__FILE__), 'plugins')}"
    ]


    def self.load_all
      Log.debug "Loading plugins..."
      Log.debug "Lookup directories: #{PLUGIN_HOME.join(", ")}"
      available.each do |p|
        load_plugin p
      end
    end
    
    # Plugin helpers
    no_commands do

      # Require root privileges
      #
      # Raises an exception if the user isn't root or using sudo
      #
      def require_root
        if `whoami`.strip.chomp !=  'root'
          raise "This plugin requires root access."
        end
      end
    end

    private
    def self.load_from_dir(dir)
      unless File.directory?(dir)
        Log.debug "Invalid plugins directory #{dir}, skipping"
        return
      end

      Dir["#{dir}/*/plugin.rb"].each do |p|
        load_plugin p
      end
    end
    
    def self.load_plugin(path)
      begin
        Log.debug "Loading #{path}"
        require path
      rescue => e
        Log.error "Error loading plugin: #{path}"
        Log.error e.message
        Log.debug e.backtrace
      end
    end

    def self.available
      available = []
      PLUGIN_HOME.each do |dir|
        unless File.directory?(dir)
          Log.debug "Invalid plugins directory, skipping"
          next
        end

        Dir["#{dir}/*/plugin.rb"].each do |p|
          available << p
          yield p if block_given?
        end
      end
      available
    end

  end
end
