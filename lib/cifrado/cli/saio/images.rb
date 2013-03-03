module Cifrado
  class Saio
    
    desc 'images', 'List images available'
    def images
      service.images.each do |i|
        Log.info "[#{i.id}]".ljust(10) + "  #{i.name}"
      end
    end

  end
end

