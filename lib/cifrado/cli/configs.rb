module Cifrado
  class CLI
    desc 'configs', 'List available configuration'
    option :print, 
           :type => :string,
           :desc => 'Print the configuration selected'
    option :current, 
           :type => :boolean,
           :desc => 'Print the current configuration'
    def configs
      cdir = Cifrado::Config.instance.config_dir

      current = "#{cdir}/cifradorc"
      if options[:current]
        if File.exist?(current)
          Log.info conceal_password(File.read("#{cdir}/cifradorc"))
          return 'cifradorc'
        else
          raise 'No configuration available.'
        end
      end

      configs = Dir["#{cdir}/cifradorc.*"].map do |c|
        File.basename(c).gsub('cifradorc.', '')
      end

      selected = options[:print]
      if selected and configs.include?(selected)
        Log.info conceal_password(File.read("#{cdir}/cifradorc.#{selected}"))
        return selected
      else
        raise "Config #{selected} not available." if selected
      end
        
      configs.each { |c| Log.info(c) if c !~ /bak\.\d+/ }
      configs
    end

    private
    def conceal_password(buf)
      buf.gsub(/^.*password:.*$/, ':password:')
    end
  end
end
