module Cifrado
  module Plugins
    class Saio
      
      desc 'images', 'List images available'
      def images
        images = service.images.all
        images.each do |i|
          Log.info "[#{i.id}]".ljust(10) + "  #{i.name}"
        end
        images
      end

    end
  end
end

