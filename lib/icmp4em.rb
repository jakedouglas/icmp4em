$:.unshift File.expand_path(File.dirname(File.expand_path(__FILE__)))
require 'eventmachine'
require 'socket'
require 'icmp4em/common'
require 'icmp4em/handler'
require 'icmp4em/icmpv4'