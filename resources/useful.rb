#!/usr/bin/ruby
# kukri 
$help = <<HELP
 Kukri
 Usage
 scriptname [interface] 
 -s		--scan			 					Scans for access points.
 -c 	--connect SSID {Hexkey|s:asciikey}	Connect to an access point	
 -d		--disconnect						Disconnect from current access point
 -h		--help								Displays this help and exits
 -i		--information						Displays SSID and signal strength

 You can edit the source file to change the default interface and DHCP client.
 Note for WEP users, if you are using an ascii key, prepend a "s:" to your key.
   ex: kukri -c accesspoint s:password
HELP
INTERFACE = :eth0 # Edit for default extension
DHCPCLIENT = :dhcpcd # Edit for default dhcp client
class WifiTools 
  def initialize interface = INTERFACE
    @interface = interface
  end

  def scan

    networks = `sudo iwlist #{@interface} scan`.split(/Cell \d*/)
    networks.shift
    networks.each do |results|		
      puts results.match(/SSID:\".*"/).to_s.gsub('"','')
      print "\t", results.match(/Channel:\d+/).to_s.concat("\n")
      print "\t", results.match(/Quality=\d+\/\d+/).to_s.sub("Quality=",'Strenth:').to_s.concat("\n")
      print "\t", results.match(/Encryption .*\s/).to_s.sub(' ',':')
    end
  end
  def connect essid, key = nil
     if `sudo ifconfig #{@interface} up` != ''
       abort("Please run the script using sudo or as root")
     end

    unless key 
      puts "Connecting to #{essid}"
      if `sudo iwconfig #{@interface} essid #{essid}` == ''
        puts "Connected to #{essid}"
      else
        abort("Could not connect")
      end
    else
      puts "Connecting to #{essid} with WEP encryption"
      if `sudo iwconfig #{@interface} essid #{essid} key #{key}` == ''
        puts "Connected to #{essid}"
      else
          abort("Could not connect")
      end
    end

    `sudo #{DHCPCLIENT} -q -n #{@interface}`
    puts "#{DHCPCLIENT.to_s.capitalize} started."
  end

  def disconnect
    "Disconnecting #{@interface}"
    if `sudo iwconfig #{@interface} essid off` != '' 
      "Disconnect failed! Try running as root"
    end
  end
  def information
    "Current Connection"
    info = `sudo iwconfig #{@interface}`
    puts info.match(/SSID:\".*"/)
    puts  info.match(/Quality=\d+\/\d+/).to_s.sub("Quality=",'Strenth:')
  end
end


#wifi = Config.new(ARGV.first) if ARGV.first =~ /\w\d/ else 
case ARGV.first() 
  when /\w\w/
    wifi = WifiTools.new(ARGV.shift)
  else
  wifi = WifiTools.new()
end

case ARGV.first()
when "--scan", "-s"
  wifi.scan
when "--connect", "-c"
    wifi.connect ARGV[1], ARGV[2]
when "--disconect", "-d"
  wifi.disconnect
when "--information", "-i"
  wifi.information
when "--help", "-h"
  print $help
else
  print $help
end