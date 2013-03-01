module Cifrado
  class RateLimit

    def initialize(bwlimit)
      @time = Time.now.to_f 
      @read = 0 
      @sleep_time = 0.01 
      @bwlimit = bwlimit
    end

    def upload(read)
      bps = @read/(Time.now.to_f - @time)
      if bps > @bwlimit
        Log.debug 'limiting rate'
        sleep @sleep_time
        @sleep_time += 0.01
      else
        @sleep_time -= 0.01 if @sleep_time >= 0.02
      end
      @read += read
    end
  end
end
