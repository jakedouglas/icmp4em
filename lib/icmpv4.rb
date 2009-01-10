module ICMP4EM

  class ICMPv4

    include Common

    attr_accessor :bind_host, :latency, :interval, :id, :debug

    @@instances = []
    @@recvsocket = nil

    def self.instances
      @@instances
    end

    # Create a new ICMP object (host). Must be passed either IP address or hostname, and 
    # optionally the interval at which it should be pinged, and timeout for the pings, in seconds.
    def initialize(host, interval = 1, timeout = 1)
      raise 'requires root privileges' if Process.euid > 0
      @host, @interval, @timeout = host, interval, timeout
      @ipv4_sockaddr = Socket.pack_sockaddr_in(0, @host)
      @waiting = []
      set_id
      @seq = 0
      @data = "Ping from EventMachine"
      @debug = false
    end

    # This must be called when the object will no longer be used, to remove 
    # the object from the class variable array that is searched for recipients when
    # an ICMP echo comes in. Better way to do this whole thing?...
    def destroy
      @@instances.delete(self)
    end

    # Send the echo request to @host and add sequence number to the waiting queue.
    def ping
      raise "EM not running" unless EM.reactor_running?
      init_handler if @@recvsocket.nil?
      seq = ping_send
      EM.add_timer(@timeout) { self.send(:expire, seq) }
    end

    # Uses EM.add_periodic_timer to ping the host at @interval.
    def schedule
      raise "EM not running" unless EM.reactor_running?
      EM.add_periodic_timer(@interval) { self.ping }
    end

    private
    
    # Expire a sequence number from the waiting queue.
    # Should only be called by the timer setup in #ping or the rescue Exception in #ping_send.
    def expire(seq)
      waiting = @waiting.find{|x| x.last == seq}
      if waiting
        str = "FAIL number #{waiting.last} from #{@host} failed. "
        str += @exception.to_s if @exception
        puts str if @debug
        @waiting.delete(waiting)
      end
    end
    
    # Should only be called by the Handler. Passes the receive time and sequence number.
    def receive(ary)
      time = ary.shift
      seq = ary.shift
      waiting = @waiting.find{|x| x.last == seq}
      if waiting
        puts "RECV number #{waiting.last} from #{@host}: Latency #{(time - waiting.first) * 1000}ms" if @debug
        @waiting.delete(waiting)
      end
    end

    # Construct and send the ICMP echo request packet.
    def ping_send
      @seq = (@seq + 1) % 65536
      begin
        socket = Socket.new(
        Socket::PF_INET,
        Socket::SOCK_RAW,
        Socket::IPPROTO_ICMP
        )
                
        if @bind_host
          saddr = Socket.pack_sockaddr_in(0, @bind_host)
          socket.bind(saddr)
        end

        # Generate msg with checksum
        checksum = 0
        msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @id, @seq, @data].pack("C2 n3 A22")
        checksum = generate_checksum(msg)
        msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @id, @seq, @data].pack("C2 n3 A22")
        # Fire it off
        socket.send(msg, 0, @ipv4_sockaddr)
        # Enqueue
        @waiting << [Time.now, @seq]
        puts "SENT number #{@seq} to #{@host}" if @debug
        @seq
      rescue Exception => err
        @exception = err
        expire(@seq)
      end
    end

    # Initialize the receiving socket and handler for incoming ICMP packets.
    def init_handler
      @@recvsocket = Socket.new(
      Socket::PF_INET,
      Socket::SOCK_RAW,
      Socket::IPPROTO_ICMP
      )
      if @bind_host
        saddr = Socket.pack_sockaddr_in(0, @bind_host)
        @@recvsocket.bind(saddr)
      end
      EM.attach @@recvsocket, Handler, @@recvsocket
    end

    # Sets the instance id to a unique 16 bit integer so it can fit inside relevent the ICMP field.
    # Also adds self to the pool so that incoming messages that it requested can be delivered.
    def set_id
      while @id.nil?
        id = rand(65535)
        unless @@instances.find{|x| x.id == id}
          @id = id
          @@instances << self
        end
      end
    end

  end
end