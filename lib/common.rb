module ICMP4EM
    
  module Common
    
    ICMP_ECHOREPLY = 0
    ICMP_ECHO      = 8
    ICMP_SUBCODE   = 0
    
    private
    
    def verify_checksum?(ary)
      cs = ary[2]
      ary_copy = ary.dup
      ary_copy[2] = 0
      cs == generate_checksum(ary_copy.pack("C2 n3 A22"))
    end

    # Perform a checksum on the message.  This is the sum of all the short
    # words and it folds the high order bits into the low order bits.
    # (This method was stolen directly from net-ping)
    def generate_checksum(msg)
      length    = msg.length
      num_short = length / 2
      check     = 0

      msg.unpack("n#{num_short}").each do |short|
        check += short
      end

      if length % 2 > 0
        check += msg[length-1, 1].unpack('C') << 8
      end

      check = (check >> 16) + (check & 0xffff)
      return (~((check >> 16) + check) & 0xffff)
    end
    
  end
  
end