module Cifrado
  module Plugins
    class Saio
      
      desc 'regions', 'List regions available'
      def regions
        regions = service.regions.all
        service.regions.each do |r|
          Log.info "[#{r.id}]".ljust(10) + "  #{r.name}"
        end
        regions
      end

    end
  end
end

