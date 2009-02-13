module ICMP4EM

  class ICMPv4

    include Common
    include HostCommon
    
    @instances = {}
    @recvsocket = nil
    
    class << self
      
      attr_reader :instances
      attr_accessor :recvsocket
      
    end
    
    attr_accessor :bind_host, :interval, :threshold, :timeout, :data
    attr_reader :id, :failures_required, :recoveries_required, :seq

    # Create a new ICMP object (host). Must be passed either IP address or hostname, and 
    # optionally the interval at which it should be pinged, and timeout for the pings, in seconds.
    def initialize(host, options = {})
      raise 'requires root privileges' if Process.euid > 0
      @host = host
      @ipv4_sockaddr = Socket.pack_sockaddr_in(0, @host)
      @interval   =   options[:interval] || 1
      @timeout    =   options[:timeout] || 1
      @stateful   =   options[:stateful] || false
      @bind_host  =   options[:bind_host] || nil
      @recoveries_required = options[:recoveries_required] || 5
      @failures_required   = options[:failures_required] || 5
      @up = true
      @waiting = {}
      set_id
      @seq, @failcount = 0, 0
      @data = "Ping from EventMachine"
    end
    
    # This must be called when the object will no longer be used, to remove 
    # the object from the class variable array that is searched for recipients when
    # an ICMP echo comes in. Better way to do this whole thing?...
    def destroy
      self.class.instances[@id] = nil
    end

    # Send the echo request to @host and add sequence number to the waiting queue.
    def ping
      raise "EM not running" unless EM.reactor_running?
      init_handler if self.class.recvsocket.nil?
      seq = ping_send
      EM.add_timer(@timeout) { self.send(:expire, seq, Timeout.new("Ping timed out")) } unless @timeout == 0
      @seq
    end

    # Uses EM.add_periodic_timer to ping the host at @interval.
    def schedule
      raise "EM not running" unless EM.reactor_running?
      EM.add_periodic_timer(@interval) { self.ping }
    end

    private

    # Expire a sequence number from the waiting queue.
    # Should only be called by the timer setup in #ping or the rescue Exception in #ping_send.
    def expire(seq, exception = nil)
      waiting = @waiting[seq]
      if waiting
        @waiting[seq] = nil
        adjust_failure_count(:down) if @stateful
        expiry(seq, exception)
        check_for_fail_or_recover if @stateful
      end
    end

    # Should only be called by the Handler. Passes the receive time and sequence number.
    def receive(seq, time)
      waiting = @waiting[seq]
      if waiting
        latency = (time - waiting) * 1000
        adjust_failure_count(:up) if @stateful
        success(seq, latency)
        check_for_fail_or_recover if @stateful
        @waiting[seq] = nil
      end
    end

    # Construct and send the ICMP echo request packet.
    def ping_send
      @seq = (@seq + 1) % 65536

      socket = self.class.recvsocket

      if @bind_host
        saddr = Socket.pack_sockaddr_in(0, @bind_host)
        socket.bind(saddr)
      end

      # Generate msg with checksum
      msg = [ICMP_ECHO, ICMP_SUBCODE, 0, @id, @seq, @data].pack("C2 n3 A*")
      msg[2..3] = [generate_checksum(msg)].pack('n')
      
      # Enqueue so we can expire properly if there is an exception raised during #send
      @waiting[seq] = Time.now
      
      begin
        # Fire it off
        socket.send(msg, 0, @ipv4_sockaddr)
        # Re-enqueue AFTER sendto() returns. This ensures we aren't adding latency if the socket blocks.
        @waiting[seq] = Time.now
        # Return sequence number to caller
        @seq
      rescue Exception => err
        expire(@seq, err)
      end
    end

    # Initialize the receiving socket and handler for incoming ICMP packets.
    def init_handler
      self.class.recvsocket = Socket.new(
      Socket::PF_INET,
      Socket::SOCK_RAW,
      Socket::IPPROTO_ICMP
      )
      if @bind_host
        saddr = Socket.pack_sockaddr_in(0, @bind_host)
        self.class.recvsocket.bind(saddr)
      end
      EM.attach self.class.recvsocket, Handler, self.class.recvsocket
    end

    # Sets the instance id to a unique 16 bit integer so it can fit inside relevent the ICMP field.
    # Also adds self to the pool so that incoming messages that it requested can be delivered.
    def set_id
      while @id.nil?
        id = rand(65535)
        unless self.class.instances[id]
          @id = id
          self.class.instances[@id] = self
        end
      end
    end

  end
  
end