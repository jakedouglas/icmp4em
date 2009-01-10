module ICMP4EM

  class ICMPv4
    
    include Common

    attr_accessor :bind_host, :latency, :interval, :id
    
    @@instances = []
    @@recvsocket = nil
    
    def self.instances
      @@instances
    end

    # Create a new ICMP object (host). Must be passed either IP address or hostname, and 
    # optionally the interval at which it should be pinged, and timeout for the pings.
    def initialize(host, interval = 5, timeout = 2)
      @host, @interval, @timeout = host, interval, timeout
      @ipv4_sockaddr = Socket.pack_sockaddr_in(0, @host)
      @waiting = []
      set_id
      @seq = 0
      @data = "Ping from EventMachine"
      puts "My ID is #{@id}"
    end
    
    # This must be called when the object will no longer be used, to remove 
    # the object from the class variable array that is searched for recipients when
    # an ICMP echo comes in. Better way to do this?...
    def destroy
      @@instances.delete(self)
    end

    def expire(msg)
      existing =  @waiting.find{|x| x.last == msg}
      if existing
        puts "Ping failed."
        @waiting.delete(existing)
      end
    end

    def receive(ary)
      time = ary.shift
      msg = ary.shift
      waiting = @waiting.find{|x| x.last == msg}
      if waiting
        #puts "#{waiting.inspect}"
        @waiting.delete(waiting)
        puts "PING RECVD from #{@host}: Latency #{(time - waiting.first) * 1000}ms"
      end
    end
    
    def ping
      raise "EM not running" unless EM.reactor_running?
      init_handler if @@recvsocket.nil?
      msg = ping_send
      EM.add_timer(@timeout) { self.expire(msg) }
    end
    
    private
    
    def ping_send
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
      @seq = (@seq + 1) % 65536
      msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @id, @seq, @data].pack("C2 n3 A22")
      checksum = generate_checksum(msg)
      ary = [ICMP_ECHO, ICMP_SUBCODE, checksum, @id, @seq, @data]
      msg = ary.pack("C2 n3 A22")
      # Fire it off
      socket.send(msg, 0, @ipv4_sockaddr)
      # Reset the checksum value to zero.
      ary[2] = 0
      # Ditch the packet type
      ary.shift
      # Enqueue
      @waiting << [Time.now, ary]
      ary
    end

    # Initialize the socket and handler for incoming ICMP packets.
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