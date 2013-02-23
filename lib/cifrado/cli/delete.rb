module Cifrado
  class CLI
    desc "delete CONTAINER [OBJECT]", "Delete specific container or object"
    def delete(container, object = nil)
      client = client_instance
      if object
        Log.info "Deleting file #{object}..."
        deleted = false
        begin
          client.service.delete_object container, object
          deleted = true
        rescue Fog::Storage::OpenStack::NotFound
          Log.debug 'Trying to find hashed object name'
          file_hash = (Digest::SHA2.new << object).to_s
          deleted = client.service.delete_object(container, file_hash) rescue nil
        end
        if deleted
          Log.info "File #{object} deleted"
        else
          Log.error "File #{object} not found"
        end
      else
        Log.info "Deleting container '#{container}'..."
        dir = client.service.directories.get(container)
        if dir
          dir.files.each do |f|
            Log.info "Deleting file #{f.key}..."
            f.destroy
          end
          dir.destroy
          Log.info "Container #{container} deleted"
        end
      end
    end
  end
end
