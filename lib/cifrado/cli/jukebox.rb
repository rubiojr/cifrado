module Cifrado
  class CLI

    desc "jukebox CONTAINER", 
         "Play music randomly from the target container"
    option :match, :type => :string
    def jukebox(container)
      client = client_instance
      token = client.service.credentials[:token]
      mgmt_url = client.service.credentials[:server_management_url]
      
      mpbin = '/usr/bin/mplayer'
      mpbin = File.exist?(mpbin) ? \
        mpbin : `which /usr/bin/mplayer`.strip.chomp
      unless File.exist?(mpbin)
        raise "MPlayer binary not found. Install it first."
      end

      dir = client.service.directories.get container
      unless dir
        raise "Container #{container} not found."
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
      $stderr.reopen('/dev/null', 'w')
      cmd = %w{mplayer -really-quiet -msglevel all=-1 -cache 256 -}
      pipe = IO.popen(cmd, 'w')
      count = songs.size
      songs.shuffle.each do |song|
        if options[:match] and song.key !~ /#{options[:match]}/i
          next
        end
        begin

          cb = Proc.new do |total, bytes, segment|
            pipe.write segment if bytes > 0 
          end

          unless (song.content_type =~ /ogg|mp3/) or \
                  song.key =~ /(mp3|wav|ogg)$/
            next
          end
          Log.info "#{set_color 'Playing', :bold} song"
          Log.info "  * #{song.key}"
          r = client.stream container, 
                            song.key, 
                            :progress_callback => cb
          Log.debug "Song finished streaming"
        rescue Interrupt => e
          Log.debug "Closing pipe, killing mplayer"
          pipe.close unless pipe.closed?
          Log.debug "Opening new pipe"
          pipe = IO.popen(cmd, 'w')
          if Time.now.to_f - last_exit < 1
            Log.info set_color "\nAdios!", :bold
            return
          else
            last_exit = Time.now.to_f
            Log.info 'Next song...'
          end
        end
      end
    ensure
      if pipe and !pipe.closed?
        Log.debug "Closing pipe"
        Process.kill 'SIGKILL', pipe.pid
        pipe.close 
      end
    end

  end
end
