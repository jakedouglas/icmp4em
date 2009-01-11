# This is an example of non-stateful usage. Only the callbacks provided in on_success and on_expire are used,
# and the object does not keep track of up/down or execute callbacks on_failure/on_recovery.

pings = []
pings << ICMP4EM::ICMPv4.new("google.com")
pings << ICMP4EM::ICMPv4.new("slashdot.org")
pings << ICMP4EM::ICMPv4.new("10.99.99.99") # host that will not respond.

Signal.trap("INT") { EventMachine::stop_event_loop }

EM.run {
  pings.each do |ping| 
    ping.on_success {|host, seq, latency| puts "SUCCESS from #{host}, sequence number #{seq}, Latency #{latency}ms"}
    ping.on_expire {|host, seq, exception| puts "FAILURE from #{host}, sequence number #{seq}, Reason: #{exception.to_s}"}
    ping.schedule
  end
}