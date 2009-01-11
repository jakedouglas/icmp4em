ICMP4EM - ping using EventMachine

http://www.github.com/yakischloba/icmp4em

Asynchronous implementation of ICMP echo/response with EventMachine. Can be used to ping many hosts at once,
with callbacks for success, timeout, and host failure/recovery based on a threshold number. This must be run 
as effective root user to use the ICMP sockets.

Simple example (see the examples/ directory for the cooler stuff):
============================================================================
require 'init'

Signal.trap("INT") { EventMachine::stop_event_loop }

host = ICMP4EM::ICMPv4.new("127.0.0.1")
host.on_success {|host, seq, latency| puts "Got echo sequence number #{seq} from host #{host}. It took #{latency}ms." }
host.on_expire {|host, seq, exception| puts "I shouldn't fail on loopback interface, but in case I did here is the reason: #{exception.to_s}"}

EM.run { host.schedule }
=>
Got echo sequence number 1 from host 127.0.0.1. It took 0.214ms.
Got echo sequence number 2 from host 127.0.0.1. It took 0.193ms.
Got echo sequence number 3 from host 127.0.0.1. It took 0.166ms.
Got echo sequence number 4 from host 127.0.0.1. It took 0.172ms.
Got echo sequence number 5 from host 127.0.0.1. It took 0.217ms.
^C
============================================================================

Please let me know what is wrong with it!

jakecdouglas@gmail.com
yakischloba on Freenode


Thanks to imperator and the others that worked on the net-ping library. I used the packet construction
and checksum code from that implementation. I will include the pertinent information from their README
at the end of this document so that nothing is missed.

Acknowledgements from "net-ping-1.2.2/doc/ping.txt": 

= Acknowledgements
   The Ping::ICMP#ping method is based largely on the identical method from
   the Net::Ping Perl module by Rob Brown. Much of the code was ported by
   Jos Backus on ruby-talk.

= Future Plans
   Add support for syn pings.

= License
   Ruby's

= Copyright
   (C) 2003-2008 Daniel J. Berger, All Rights Reserved

= Warranty
   This package is provided "as is" and without any express or
   implied warranties, including, without limitation, the implied
   warranties of merchantability and fitness for a particular purpose.

= Author
   Daniel J. Berger
   djberg96 at gmail dot com
   imperator on IRC (irc.freenode.net)
