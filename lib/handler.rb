module ICMP4EM

  module Handler
    
    include Common

    def initialize(socket)
      @socket = socket
    end

    def notify_readable
      receive(@socket)
    end

    def receive(socket)
      time = Time.now
      host, data = read_socket(socket)
      msg = data[20,30].unpack("C2 n3 A22")
      # Verify the packet type is echo reply and verify integrity against the checksum it provided
      return unless msg.first == ICMP_ECHOREPLY && verify_checksum?(msg)
      # Reset checksum to 0
      msg[2] = 0
      # Get rid of the packet type
      msg.shift
      # Find which object it is supposed to go to
      receiver = ICMPv4.instances.find{|x| x.id == msg[2]}
      # Send to object
      receiver.receive([time, msg]) unless receiver.nil?
    end

    def read_socket(socket)
      data, sender = socket.recvfrom(50)
      host = Socket.unpack_sockaddr_in(sender).last
      [host, data]
    end

  end

end