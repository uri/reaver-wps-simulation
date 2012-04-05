#!usr/bin/env ruby

### Tiny Reaver
# Author: Uri Gorelik
# Copyright 2012
#
# A Ruby implementation of the Reaver attack

# ===========================================

# TODO
# => Commands

# Tiny Reaver will require the following utility
# => Scan
# => Send message
# => Receive message
# => Default PIN list
# => Brute force attack

require "./RouterSim.rb"
require "./TinyReaverCommon.rb"

class TinyReaver
  # Inlcude some constants
  include TinyReaverCommon
  
  # Set the public variables
  attr_accessor :router, :target, :pin
  
  # Class variables
  @@log = ""
  
  TIME_FACTOR = 0.2
  TIME_MSG_TRANSACTION = 1.2
  TIME_ASSOCIATION = 3.0
  
  ##################################################
  # Class methods
  #
  
  # Log 
  def self.log type, text=""
    
    current_log = ""
    
    case type
    when :out
      current_log += "[+] #{text}\n"

    when :event
      current_log += "[!] #{text}\n"

    when :db
      current_log += "[?] #{text}\n"
      
    when :er
      current_log += "[x] #{text}\n"

    when :nl
      current_log += "\n"
    end
    
    @@log += current_log
    
    # Return the current log
    puts current_log
  end
  
  
  # Scan
  def self.scan
    log :out, "Scanning for networks"
    # Pretend we found a router
    log :out, "Found hosts:"
    log :nl
    log :out, "SSID"
    log :out, "#{RouterSim.new.ssid}"
    log :nl
    
  end
  
  
  ##################################################
  # PUBLIC Instance methods
  #
  
  # Init
  def initialize target
    @router = RouterSim.new
    @target = target
    @current_pin = 0
    @half_pin = -1
    @pin = -1
    @state = STATE_BEGIN
    @time_factor = TIME_FACTOR
  end
  
  
  # Attack main loop
  def attack
    start_time = Time.now
    
    # We have to authenticate with the router
    @state = STATE_BEGIN
    
    
    # Authentication phase
    while @state == STATE_BEGIN
      log :out, "Associating with router..."
      
      sleep TIME_ASSOCIATION * @time_factor
      
      authenticate
    end
    
    
    log :out, "Association complete, beginning attack."
    
    while @state == STATE_ASSOC  
      sleep TIME_MSG_TRANSACTION * @time_factor
      
      log :out, "Trying pin #{pad_pin}"
      
      outgoing_msg = create_message :m4, pad_pin
      reply = send_message(outgoing_msg)
      
#      log :db, "Made message: #{outgoing_msg}"
#      log :db, "Got reply: #{reply}"
      
      receive_message reply
      
    end
    
    while @state == STATE_HALF_DONE
      sleep TIME_MSG_TRANSACTION * @time_factor
      
      log :out, "Trying pin #{pad_pin_2}"
      
      outgoing_msg = create_message :m6, pad_pin_2
      reply = send_message(outgoing_msg)
      
      receive_message reply
    end
    
    # We have completed the attack
    # display notification
    
    log :event, "Time: #{Time.now - start_time}"
    log :nl
      
  end
  
  
  ##################################################
  # PRIVATE Instance methods
  #
  private
  
  def pad_pin
    ret = "#{@current_pin}"
    
    (4 - ret.length).times {
      ret = "0" + ret
    }
    
    ret += "0000"
    
    return ret
    
  end
  
  def pad_pin_2
    first_half = "#{@half_pin}"
    
    (4 - first_half.length).times {
      first_half = "0" + first_half
    }
    
    second_half = "#{@current_pin}"
    (3 - second_half.length).times {
      second_half = "0" + second_half
    }

    # Get the checksum
    
    checksum = "#{first_half}#{second_half}".unpack('B*')[0].count("1") % 10
    
    return "#{first_half}#{second_half}#{checksum}"
    
  end
  
  def log type, content=""
    TinyReaver.log type, content
  end
  
  
  # Authenticate
  def authenticate
    receive_message @router.authenticate_message
  end
  
  
  # Genereate a pin
  def next_pin
    @current_pin += 1
  end
  
  
  ### Messaging
  
  # Create a message
    def create_message type, payload=""
      case type
        
      ### Attacker messages
      when :m2
        "#{MSG_M2}:Association request."
      when :m4
        "#{MSG_M4}:#{payload}"
      when :m6
        "#{MSG_M6}:#{payload}"
      end  
    end
    
    
    # Receive a message
    def receive_message msg
      if msg == "EAPNAK"
        log :out, "Received EAPNAK for #{@state == STATE_HALF_DONE ? pad_pin_2 : pad_pin}, trying next pin..."
        next_pin
      end
      
      msg_array = msg.split ":"
      msg_type = msg_array[0]
      msg_content = msg_array[1]
      
      
      case msg_type

      # Beacon message from router
      when MSG_M1
        
        log :event, "Received M1, sending reply."
        send_message(create_message(:m2))
        
        # sleep 2
        
        receive_message @router.assoc_message
        
      # Association message
      when MSG_M3
        # Change the state to associated
        @state = STATE_ASSOC
        log :event, "Received M3: '#{msg_content}'"
        
      when MSG_M5
        # We have the first 4 digits of the pin
        @state = STATE_HALF_DONE
        log :event, "Received M5, pin is #{pad_pin[0..3]}XXXX"
        
        # Save the half pin
        @half_pin = pad_pin[0..3]
        # Reset the pin
        @current_pin = 0
      when MSG_M7
        @state = STATE_ATTACK_SUCCESSFUL
        log :event, "Received M7, attack complete"
        log :event, "SSID: #{@router.ssid}"
        log :event, "PSK: #{msg_content}"
      end
      
      
    end
    
    
    # Send message
    def send_message msg
      @router.receive_message msg
    end
    
end


############ ############ ############ ############ 
# Running
#
`clear`

case ARGV.shift
when "--scan", "-s"
  # Perform a scan
  reaver = TinyReaver.scan
when "--ssid", "-b"
  reaver = TinyReaver.new ARGV.shift
  start = Time.now
  reaver.attack
  endTime = Time.now - start
  
  
end