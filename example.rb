require 'init'

pings = []
pings << ICMP4EM::ICMPv4.new("google.com")
pings << ICMP4EM::ICMPv4.new("slashdot.org")

Signal.trap("INT") { EventMachine::stop_event_loop }

EM.run {
  pings.each {|ping| ping.debug = true; ping.schedule }
}