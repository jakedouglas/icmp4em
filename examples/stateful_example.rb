# This example shows stateful usage, which tracks up/down state of the host based on consecutive number
# of successful or failing pings specified in failures_required and recoveries_required. Hosts start in
# 'up' state.

pings = []
pings << ICMP4EM::ICMPv4.new("google.com", :stateful => true, :recoveries_required => 5, :failures_required => 5)
pings << ICMP4EM::ICMPv4.new("10.1.0.175", :stateful => true, :recoveries_required => 5, :failures_required => 5) # host that will not respond.

Signal.trap("INT") { EventMachine::stop_event_loop }

EM.run {
  pings.each do |ping| 
    ping.on_success {|host, seq, latency, count_to_recovery| puts "SUCCESS from #{host}, sequence number #{seq}, Latency #{latency}ms, Recovering in #{count_to_recovery} more"}
    ping.on_expire {|host, seq, exception, count_to_failure| puts "FAILURE from #{host}, sequence number #{seq}, Reason: #{exception.to_s}, Failing in #{count_to_failure} more"}
    ping.on_failure {|host| puts "HOST STATE WENT TO DOWN: #{host} at #{Time.now}"}
    ping.on_recovery {|host| puts "HOST STATE WENT TO UP: #{host} at #{Time.now}"}
    ping.schedule
  end
}