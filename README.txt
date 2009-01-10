ICMP4EM - ping using EventMachine

http://www.github.com/yakischloba/icmp4em

Asynchronous implementation of ICMP echo/response with EventMachine. Can be used to ping many hosts at once,
with callbacks for success, timeout, and host failure/recovery based on a threshold number. (Still need to
port the callbacks from my original blocking app.) This must be run as effective root user to use the ICMP
sockets.

Example:

yakischloba:~/development/icmp4em jake$ sudo irb
irb(main):001:0> require 'init'
irb(main):002:0> pings = []
irb(main):003:0> pings << ICMP4EM::ICMPv4.new("10.1.0.1")
irb(main):004:0> pings << ICMP4EM::ICMPv4.new("10.1.0.3")
irb(main):005:0> pings << ICMP4EM::ICMPv4.new("10.1.0.175")
irb(main):006:0> Signal.trap("INT") { EventMachine::stop_event_loop }
irb(main):007:0> EM.run { pings.each {|ping| ping.debug = true; ping.schedule } } 
SENT number 1 to 10.1.0.1
SENT number 1 to 10.1.0.3
SENT number 1 to 10.1.0.175
RECV number 1 from 10.1.0.1: Latency 1.107ms
RECV number 1 from 10.1.0.3: Latency 1.99199999999999ms
RECV number 1 from 10.1.0.175: Latency 10.634ms
SENT number 2 to 10.1.0.1
SENT number 2 to 10.1.0.3
SENT number 2 to 10.1.0.175
RECV number 2 from 10.1.0.1: Latency 1.077ms
RECV number 2 from 10.1.0.3: Latency 1.656ms
RECV number 2 from 10.1.0.175: Latency 9.028ms
SENT number 3 to 10.1.0.1
SENT number 3 to 10.1.0.3
SENT number 3 to 10.1.0.175
RECV number 3 from 10.1.0.1: Latency 1.044ms
RECV number 3 from 10.1.0.3: Latency 1.538ms
RECV number 3 from 10.1.0.175: Latency 9.0ms
^C

Latency is not very accurate yet, when pinging many hosts.

Please let me know what else is wrong with it!

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
