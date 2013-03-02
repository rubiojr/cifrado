module Cifrado
  class CLI

    desc "jukebox CONTAINER", 
         "Play music randomly from the target container"
    option :match, :type => :string
    def jukebox(container)
      client = client_instance
      
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
      pipe = IO.popen(player_command, 'w')
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
        rescue Timeout::Error, Errno::EPIPE, Interrupt => e
          Log.debug "Closing pipe"
          prettify_backtrace e
          pipe.close unless pipe.closed?
          Log.debug "Opening new pipe"
          pipe = IO.popen(player_command, 'w')
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
        Log.debug "Closing pipe, killing mplayer"
        Process.kill 'SIGKILL', pipe.pid
        pipe.close 
      end
    end

    private
    def player_command
      cvlc = '/usr/bin/cvlc'
      vlc = '/usr/bin/vlc'
      mplayer = '/usr/bin/mplayer'
      totem = '/usr/bin/totem'

      if File.exist?(cvlc)
        Log.debug "Using cvlc player"
        '/usr/bin/cvlc -' 
      elsif File.exist?(mplayer)
        Log.debug "Using mplayer player"
        '/usr/bin/mplayer -really-quiet -msglevel all=-1 -cache 256 -'
      elsif File.exist?(vlc)
        Log.debug "Using vlc player"
        '/usr/bin/vlc -'
      elsif File.exist?(totem)
        Log.debug "Using totem player"
        '/usr/bin/totem --enqueue fd://0'
      else
        raise "No player available. Install MPlayer, VLC or totem."
      end
    end

  end
end
