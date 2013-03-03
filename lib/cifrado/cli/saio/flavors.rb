module Cifrado
  class Saio
    
    desc 'flavors', 'List image flavors available'
    def flavors
      service.flavors.each do |f|
        Log.info "[#{f.id}]".ljust(5) + "  #{f.name}"
      end
    end

  end
end

