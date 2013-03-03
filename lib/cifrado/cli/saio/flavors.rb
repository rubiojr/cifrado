module Cifrado
  module Plugins
    class Saio
      
      desc 'flavors', 'List image flavors available'
      def flavors
        flavors = service.flavors.all
        flavors.each do |f|
          Log.info "[#{f.id}]".ljust(5) + "  #{f.name}"
        end
        flavors
      end

    end
  end
end

