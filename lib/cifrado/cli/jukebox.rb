module Cifrado
  class CLI

    desc "jukebox CONTAINER", 
         "Play music randomly from the target container"
    option :match, :type => :string
    def jukebox(container)
      client = client_instance
      token = client.service.credentials[:token]
      mgmt_url = client.service.credentials[:server_management_url]
      
      tmpout = "/tmp/#{SecureRandom.hex}"

      mpbin = '/usr/bin/mplayer'
      mpbin = File.exist?(mpbin) ? \
        mpbin : `which /usr/bin/mplayer`.strip.chomp
      unless File.exist?(mpbin)
        Log.error "MPlayer binary not found. Install it first."
        exit 1
      end

      pipe = nil
      cb = Proc.new do |total, bytes, segment|
        pipe.write segment if bytes > 0
      end

      dir = client.service.directories.get container
      unless dir
        Log.error "Container #{container} not found."
        exit 1
      end
      songs = dir.files
      last_exit = Time.now.to_f

      Log.info
      Log.info set_color "Cifrado Jukebox", :bold
      Log.info "---------------"
      Log.info
      Log.info set_color("Ctrl-C once", :bold)+ "   -> next song"
      Log.info set_color("Ctrl-C twice", :bold)+ "  -> quit"
      Log.info
      songs.shuffle.each do |song|
        pipe = IO.popen("mplayer -cache 256 - > /dev/null 2>&1", "w")
        if options[:match] and song.key !~ /#{options[:match]}/i
          next
        end
        begin
          unless (song.content_type =~ /audio|ogg|mp3/) or \
                  song.key =~ /(mp3|wav|ogg)$/
            next
          end
          Log.info "#{set_color 'Playing', :bold} song"
          Log.info "  * #{song.key}"
          r = client.download container, 
                              song.key, 
                              :output => tmpout,
                              :progress_callback => cb
          File.delete tmpout
        rescue Interrupt => e
          if Time.now.to_f - last_exit < 1
            Log.info set_color "\nAdios!", :bold
            exit 0
          else
            last_exit = Time.now.to_f
            Log.info 'Next song...'
          end
        rescue => e
          Log.error "Error streaming song #{song.key}"
          raise e
        ensure
          Log.debug "Closing pipe for #{song.key}"
          pipe.close
        end
      end
    rescue SystemExit
    rescue => e
      Log.error e.message
      Log.debug e.backtrace
    ensure 
      pipe.close if pipe
    end

  end
end
