module Cifrado
  class Progressbar

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
      else
        nil
      end
    end
    
    private
    def fancy
      require 'ruby-progressbar'
      title = (@segments == 1 ? \
               'Progress' : "Segment [#{@current_segment}/#{@segments}]")
      progressbar = ProgressBar.create :title => title, :total => 100

      if RUBY_VERSION =~ /1\.8/
        # See https://github.com/jfelchner/ruby-progressbar/pull/25
        Log.warn "Progressbar performance is very poor under Ruby 1.8"
        Log.warn "If you are getting low throughtput when uploading"
        Log.warn  "upgrade to Ruby 1.9.X or use '--progressbar fast'"
      end

      read = 0
      Proc.new do |total, bytes, nchunk| 
        read += bytes
        unless read > total
          increment = (bytes*100.0)/total
          percentage = ((read*100.0/total)).round
          progressbar.title = "#{title} (#{percentage}%)"
          if progressbar.progress + increment <= 100
            progressbar.progress += increment
          else
            progressbar.finish
          end
        end
      end
    end

    def fast
      if @segments != 1
        title = "[#{@current_segment}/#{@segments}]"
      else
        title = ""
      end
      read = 0
      progressbar_finished = false
      return Proc.new do |tbytes, bytes, nchunk| 
        read += bytes
        percentage = ((read*100.0/tbytes))
        if ((percentage % 10) < 0.1) and read <= tbytes
          print "\r"
          print "Progress (#{percentage.round}%) #{title}: "
          print '#' * (percentage/10).floor
        end
        if (read + bytes) >= tbytes and !progressbar_finished
          progressbar_finished = true
          percentage = 100
          print "\r"
          print "Progress (#{percentage.round}%) #{title}: "
          print '#' * (percentage/10).floor
          puts
        end
      end
    end

  end
end
