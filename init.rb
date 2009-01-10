require 'rubygems'
require 'eventmachine'
require 'socket'
require 'timeout'
require 'lib/common'
require 'lib/handler'
require 'lib/icmpv4'

pings = []
pings << ICMP4EM::ICMPv4.new("10.1.0.1", 1, 1)
#pings << ICMP4EM::ICMPv4.new("10.1.0.3", 1, 1)
#pings << ICMP4EM::ICMPv4.new("10.1.0.175", 1, 1)

Signal.trap("INT") { EventMachine::stop_event_loop }

EM.run {
  pings.each do |x|
    EM.add_periodic_timer(x.interval) { x.ping }
  end
}