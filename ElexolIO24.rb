require 'socket'

class ElexolIO24

	CMD_IDENTIFY = "IO24"
	CMD_WRITE_PORT_A = "A"
	CMD_WRITE_PORT_A_DIRECTION = "!A"
	CMD_ECHO = "`"
	
	ON = 1
	OFF = 0
	
	OUT1 = 0b00000001
	OUT2 = 0b00000010
	OUT3 = 0b00000100
	OUT4 = 0b00001000
	OUT5 = 0b00010000
	OUT6 = 0b00100000
	OUT7 = 0b01000000
	OUT8 = 0b10000000

	
	BROADCAST = "<broadcast>"
	
	UDP_PORT = 2424
	
	UDP_RECV_TIMEOUT = 3
	
	attr_accessor :address
	attr_accessor :host_name
	attr_accessor :mac_address
	attr_accessor :fw_version
	
	def self.find
		units = []
		resp = nil
	  connection do |socket|   
			socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
	    socket.send(CMD_IDENTIFY, 0, BROADCAST, UDP_PORT)
	    resp = if select([socket], nil, nil, UDP_RECV_TIMEOUT)
	      socket.recvfrom(12)
	    end
		end 
    #resp = 'IO24mmmmmmvv'
    #resp = '012345678901'
    if resp
    	#create a new ElexolIO24 object for each responding unit
    	#don't have two units to test, so just assume there is one response
    	unit = ElexolIO24.new
    	unit.address = resp[1][3]
    	unit.host_name = resp[1][2]
    	unit.mac_address = resp[0][4..10] 
    	unit.fw_version = resp[0][10..11]
    	units << unit
    end
    units
	end
	
	def initialize(opts={:class_colour => RED})
		opts.each do |name, value|
			instance_variable_set("@#{name}", value)
		end
	end
	
	def set_output(outs)
		out_byte = 0
		outs.each do |key, value|
			out_byte |= 2**(key-1) if value == ON
		end
		#cheat and combine two commands
		#!A\000 sets all outputs on port a to outputs
		#A\.... sets the state of the output 
		cmd = CMD_WRITE_PORT_A_DIRECTION + "\000" + CMD_WRITE_PORT_A + [out_byte].pack('C*')
		ElexolIO24.connection do |socket|   
			socket.send(cmd, 0, @address, UDP_PORT)
		end 
	end
	
	
	def echo(byte='E')
		_resp = nil
		_cmd = CMD_ECHO + byte
	  ElexolIO24.connection do |socket|   
	    socket.send(_cmd, 0, @address, UDP_PORT)
	    _resp = if select([socket], nil, nil, UDP_RECV_TIMEOUT)
	      socket.recvfrom(2)
	    end
		end 
    _resp
	end

	def connected?
		_byte == 'E'
		return _byte == self.echo(_byte) 
	end
	
	private
	def self.connection
		begin
			socket = UDPSocket.open  
			yield(socket)   
		ensure   
			socket.close if socket
		end 
	end
end
