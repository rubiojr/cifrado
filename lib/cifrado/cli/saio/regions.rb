module Cifrado
  class Saio
    
    desc 'regions', 'List regions available'
    def regions
      service.regions.each do |r|
        Log.info "[#{r.id}]".ljust(10) + "  #{r.name}"
      end
    end

  end
end

