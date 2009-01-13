module ICMP4EM

  class Timeout < Exception; end;

  module Common

    ICMP_ECHOREPLY = 0
    ICMP_ECHO      = 8
    ICMP_SUBCODE   = 0

    private

    # Perform a checksum on the message.  This is the sum of all the short
    # words and it folds the high order bits into the low order bits.
    # (This method was stolen directly from net-ping - yaki)
    def generate_checksum(msg)
      length    = msg.length
      num_short = length / 2
      check     = 0

      msg.unpack("n#{num_short}").each do |short|
        check += short
      end

      if length % 2 > 0
        check += msg[length-1, 1].unpack('C').first << 8
      end

      check = (check >> 16) + (check & 0xffff)
      return (~((check >> 16) + check) & 0xffff)
    end

  end

  module HostCommon

    # Set failure callback. The provided Proc or block will be called and yielded the host and sequence number, whenever the failure count exceeds the defined threshold.
    def on_failure(proc = nil, &block)
      @failure = proc || block unless proc.nil? and block.nil?
      @failure
    end

    # Set recovery callback. The provided Proc or block will be called and yielded the host and sequence number, whenever the recovery count exceeds the defined threshold.
    def on_recovery(proc = nil, &block)
      @recovery = proc || block unless proc.nil? and block.nil?
      @recovery
    end

    # Set success callback. This will be called and yielded the host, sequence number, and latency every time a ping returns successfully.
    def on_success(proc = nil, &block)
      @success = proc || block unless proc.nil? and block.nil?
      @success
    end

    # Set 'expiry' callback. This will be called and yielded the host, sequence number, and Exception every time a ping fails. 
    # This is not just for timeouts! This can be triggered by failure of the ping for any reason.
    def on_expire(proc = nil, &block)
      @expiry = proc || block unless proc.nil? and block.nil?
      @expiry
    end

    # Set the number of consecutive 'failure' pings required to switch host state to 'down' and trigger failure callback, assuming the host is up.
    def failures_required=(failures)
      @failures_required = failures
    end
    
    # Set the number of consecutive 'recovery' pings required to switch host state to 'up' and trigger recovery callback, assuming the host is down.
    def recoveries_required=(recoveries)
      @recoveries_required = recoveries
    end
    
    private

    def success(seq, latency)      
      if @success
        if @stateful
          count_to_recover = @up ? 0 : @recoveries_required - @failcount.abs
          @success.call(@host, seq, latency, count_to_recover)
        else
          @success.call(@host, seq, latency)
        end
      end
    end

    def expiry(seq, reason)
      if @expiry
        if @stateful
          count_to_fail = @up ? @failures_required - @failcount : 0
          @expiry.call(@host, seq, reason, count_to_fail)
        else
          @expiry.call(@host, seq, reason)
        end
      end

    end

    # Executes specified failure callback, passing the host to the block.
    def fail
      @failure.call(@host) if @failure
      @up = false
    end

    # Executes specified recovery callback, passing the host to the block.
    def recover
      @recovery.call(@host) if @recovery
      @up = true
    end

    # Trigger failure/recovery if either threshold is exceeded...
    def check_for_fail_or_recover
      if @failcount > 0
        fail if @failcount >= @failures_required && @up
      elsif @failcount <= -1
        recover if @failcount.abs >= @recoveries_required && !@up
      end
    end

    # Adjusts the failure counter after each ping. The failure counter is incremented positively to count failures,
    # and decremented into negative numbers to indicate successful pings towards recovery after a failure.
    # This is an awful mess..just like the rest of this file.
    def adjust_failure_count(direction)
      if direction == :down
        if @failcount > -1 
          @failcount += 1
        elsif @failcount <= -1 
          @failcount = 1
        end
      elsif direction == :up && !@up
        if @failcount > 0
          @failcount = -1
        elsif @failcount <= -1
          @failcount -= 1
        end
      else
        @failcount = 0
      end
    end

  end

end