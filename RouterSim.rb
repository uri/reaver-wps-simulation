#!usr/bin/ruby

### Tiny Reaver
# Author: Uri Gorelik
# Copyright 2012
#

# ===========================================


require './TinyReaverCommon.rb'

class RouterSim
  include TinyReaverCommon
  attr_accessor :ssid, :psk
  
  def initialize params=nil
    @ssid = "00:11:22:33:44:55"
    @pin = "00050128"
    @psk = "SuperSecurep@assw3rd"
    
    if params
      @ssid = params[:ssid] unless !params[:ssid]
      @pin= params[:pin] unless !params[:pin]
      @psk= params[:psk] unless !params[:psk]
    end
  end
  
  
  def authenticate_message
    create_message :m1
  end
  
  def assoc_message
    create_message :m3
  end
  
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
      "#{MSG_M5}:Half pin verified"    
    when :m7
      "#{MSG_M7}:#{@psk}"
    end
    
  end
  
  
  # Receive a message
  def receive_message msg 
    
    
    msg_array = msg.split ":"
    msg_type = msg_array[0]
    msg_content = msg_array[1]
    

    
    case msg_type
       
    when MSG_M4
      # Check if PIN is correct
      if @pin[0..3] == msg_content[0..3]
        create_message :m5
      else
        create_message :NAK
      end
    when MSG_M6
      if @pin == msg_content
        create_message :m7
      else
        create_message :NAK
      end
      
    end
    
    
  end

  
end