module Cifrado
  class Progressbar
    include Cifrado::Utils

    def initialize(segments, current_segment, options = {})
      @style = (options[:style] || :fancy).to_sym
      @segments = segments
      @current_segment = current_segment
    end

    def block
      if @style == :fancy
        fancy 
      elsif @style == :fast
        fast
      elsif @style == :infinite
        infinite
      else
        nil
      end
    end
    
    private
    def fancy
      require 'ruby-progressbar'
      title = (@segments == 1 ? \
               'Progress' : "Segment [#{@current_segment}/#{@segments}]")
      progressbar = ProgressBar.create :title => title, :total => 100,
                                       :format => '%t: |%B| %p%% [%E ]'
      read = 0
      percentage = 0
      time = Time.now.to_f
      last_time = Time.now.to_f
      Proc.new do |total, bytes| 
        next if total == 0
        read += bytes
        newt = Time.now.to_f 
        if newt - last_time > 1
          last_time = newt
          percentage = (read*100/total)
          kbs = "%0.2f" % (read*8/((Time.now.to_f - time)*1024*1024))
          progressbar.title = " [#{kbs} Mb/s] #{title}"
          progressbar.progress = percentage unless percentage > 100
        end
        progressbar.finish if (progressbar.progress < 100) and \
          read >= total
      end
    end

    def infinite
      read = 0
      time = Time.now.to_f
      Proc.new do |tbytes, bytes| 
        read += bytes
        kbs = "%0.2f" % (read*8/((Time.now.to_f - time)*1024*1024))
        print "Progress (unknown total size): #{humanize_bytes(read).ljust(10)} read (#{kbs} Mb/s)".ljust(60)
        print "\r"
      end
    end

    def fast
      title = (@segments == 1) ? ' ' : \
              " [#{@current_segment}/#{@segments}]"

      read = 0
      progressbar_finished = false
      time = Time.now.to_f
      Proc.new do |tbytes, bytes| 
        read += bytes
        percentage = ((read*100.0/tbytes))
        kbs = "%0.2f" % (read*8/((Time.now.to_f - time)*1024*1024))
        print "\r"
        print "Progress (#{percentage.round}%) #{kbs} Mb/s#{title}: "
        print "#{humanize_bytes(read)} read"
        if (read + bytes) >= tbytes and !progressbar_finished
          progressbar_finished = true
          percentage = 100
          print "\r"
          print "Progress (#{percentage.round}%) #{title}: "
          puts
        end
      end
    end

  end
end
