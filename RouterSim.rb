#!usr/bin/ruby

### Tiny Reaver
# Author: Uri Gorelik
# Copyright 2012
#

# ===========================================

require './TinyReaverCommon.rb'

class RouterSim
  include TinyReaverCommon
  attr_accessor :ssid
  
  def initialize params=nil
    @ssid = "00:11:22:33:44:55"
    @pin = 12345670
    
    if params
      @ssid = params[:ssid] unless !params[:ssid]
      @pin= params[:pin] unless !params[:pin]
    end
  end
  
  
  def authenticate_message
    create_message :m1
  end
  
  
  private
  ### Messaging
  
  # Create a message
  def create_message type
    case type
      
    when :NAK
      "EAPNAK"
    when :m1
      "#{MSG_M1}:Beacon message"
    when :m3
      "#{MSG_M3}:Association request ACCEPTED."
    when :m5
      "#{MSG_M5}:23ed76"    
    when :m7
      "#{MSG_M7}:#{@psk}"
    end
    
  end
end