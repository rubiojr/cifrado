module Cifrado
  class CLI

    desc "cinema CONTAINER VIDEO", 
         "Stream videos from the target container"
    option :subtitles, :type => :boolean
    def cinema(container, video)
      client = client_instance
      
      dir = client.service.directories.get container
      unless dir
        raise "Container #{container} not found."
      end
      
      to_play = dir.files.find { |v| v.key =~ /#{video}/ }
      unless to_play
        raise "No video matches #{video}"
      end

      sub_file = nil
      if options[:subtitles]
        begin
          Log.info "Subtitles found, downloading."
          sub_object = to_play.key.gsub(/\.(avi|mpeg|mov)$/, '') + '.srt'
          sub = client.head container, sub_object
          sub_file = "/tmp/#{SecureRandom.hex}"
          client.download container, sub_object, :output => sub_file
        rescue => e
          Log.error "Error downloading subtitles, ignoring."
        end
      end

      $stderr.reopen('/dev/null', 'w')
      pipe = IO.popen(player_command(sub_file), 'w')
      begin
        cb = Proc.new do |total, bytes, segment|
          pipe.write segment if bytes > 0 
        end

        Log.info "#{set_color 'Playing', :bold} #{to_play.key}"
        r = client.stream container, 
                          to_play.key, 
                          :progress_callback => cb
        Log.debug "Video finished streaming"
      rescue => e
        Log.debug "Closing pipe"
        prettify_backtrace e
        pipe.close unless pipe.closed?
        Log.info set_color "\nAdios!", :bold
      end
    end

    private
    def player_command(subtitles = nil)
      cvlc = '/usr/bin/cvlc'
      vlc = '/usr/bin/vlc'
      mplayer = '/usr/bin/mplayer'
      totem = '/usr/bin/totem'

      if File.exist?(cvlc)
        Log.debug "Using cvlc player"
        extra_args = "--sub-file #{subtitles}" if subtitles
        "/usr/bin/cvlc #{extra_args} -" 
      elsif File.exist?(mplayer)
        extra_args = "-sub #{subtitles}" if subtitles
        Log.debug "Using mplayer player"
        "/usr/bin/mplayer #{extra_args} -really-quiet -msglevel all=-1 -cache 256 -"
      elsif File.exist?(vlc)
        Log.debug "Using vlc player"
        extra_args = "--sub-file #{subtitles}" if subtitles
        "/usr/bin/vlc #{extra_args} -"
      elsif File.exist?(totem)
        Log.debug "Using totem player"
        '/usr/bin/totem --enqueue fd://0'
      else
        raise "No player available. Install MPlayer, VLC or totem."
      end
    end

  end
end
