#ShoutOut to @donpdonp for suggesting Shoes for gui
require 'rubygems'
SHOES_APP = File.expand_path(__FILE__)
require 'shoes'
require 'digest/sha1'
require 'json'
require 'socket'

class GilliesRSA
  def self.mymodulus
    0xcc0f26cd602216e149fe8c2b4027293cd05cd5ccb8720d48a3e50c11c4ce5402cbd3d186e05f5bf15acb078c945f3ca99d0f1b4c7a01722704981afe7ba58f5b
  end

  def self.mysign(msg)
    sha1 = Digest::SHA1.hexdigest(msg)
    #modulus hex encoded
    n= self.mymodulus
    #decryption exponent hex encoded
    d = 0x880b6df62caa6d90a3d166480b8c504cf029848ce947789dbe4f1d7dd7352c0243dc83e5c7704632b0ad55e9086c11deb7bbda791b59a2eca8da99be6dde6a79
    self.sign(sha1, n, d).to_s(16)
  end

  #third time i ported this fucking function, thanks @donpdonp and @reidab
  def self.sign(sHashHex, pub, priv) #this function copied from the rsa.js script included in Tom Wu's jsbn library
    sMid = ""
    fLen = ((pub.size*8) / 4) - sHashHex.length - 6
    i = 0
    #p "FLEN #{fLen}"
    sMid = "f"*fLen
    #p "SMID: #{sMid.length}"
    hPM = "0001" + sMid + "00" + sHashHex #this pads the hash to desired length - not entirely sure whether those 'ff' should be random bytes for security or not
    x = hPM.to_i(16) #turn the padded message into a jsbn BigInteger object
    #p "X: #{x}, PRIV: #{priv}, PUB: #{pub}"
    return Math.power_modulo(x,priv,pub) #$x->modPow($d, $n)
  end

  def self.verify(modulus, message, signature)
    n = modulus.to_i(16)
    x = signature.gsub(/[ \n]+/, "").to_i(16)
    return Math.power_modulo(x,"10001".to_i(16), n).to_s(16).gsub(/^1f+00/, '') == Digest::SHA1.hexdigest(message)
  end
end

class UDPMessage
  def initialize(socket)
    @socket = socket
    @br = 0
  end
  attr_accessor :hostname, :port, :body, :line, :me, :br
  def send_message
    @socket.send self.body, 0, self.hostname, self.port
  end
end

def Math.power_modulo(b, p, m)
  if p == 1
    b % m
  elsif (p & 0x1) == 0 # p.even?
    t = power_modulo(b, p >> 1, m)
    (t * t) % m
  else
    (b * power_modulo(b, p-1, m)) % m
  end
end

class TeleHash
  Server = 'telehash.org'
  Port = 42424
  def self.send(data)
    sock = UDPSocket.new
    sock.send(data, 0, Server, Port)
    sock.close
  end
end

Shoes.app :width => 500, :height => 300 do

  def stacker
    colors = []
    100.times do 
      colors << white
    end
    #colors = ['#00f','#f00', '#0f0']
    matrix_y = 1
    matrix_x = 1
    colors.each do |color|
      baz = stack :width => 30, :height => 30 do
      
        fill color
        stroke color
        foo = self
        click do |b,x,y|
          #alert("clicked on #{color} square")
          p baz
          thisColor = "#%06x" % (rand * 0xffffff)
          matrix_x = $stacks.select do |stack|
            stack[0] == baz
          end.first[1]
          baz.fill thisColor
          baz.stroke thisColor
          baz.rect(0,0,30,30)
          msg = thisColor
          p msg
          sig = GilliesRSA.mysign(msg)
          telex = { "+key" => GilliesRSA.mymodulus.to_s(16), 
                    "_hop" => 1,
                    "+end" => "8bf1cce916417d16b7554135b6b075fb16dd26ce",
                    "_to"=>"208.68.163.247:42424", 
                    "+sig"=>sig, 
                    "+message"=>msg,
                    "+matrix_x" => matrix_x,
                    "+matrix_y" => matrix_y
                  }.to_json
          p "TELEX: #{telex}"
          TeleHash.send(telex)
        end
        rect(0,0,30,30)
      end
      #p baz.methods - Object.methods

      $stacks << [ baz, matrix_x, matrix_y ]
    
      p "foo"
      matrix_x += 1
    end
    rescue => e
      p e 
      puts e.backtrace
  end

  def drawer(response_json)
    if response_json.has_key? "+key" 
      if GilliesRSA.verify(response_json["+key"], response_json["+message"], response_json["+sig"])
        #p $stacks
        $stacks.each do |stack|
          #p stack[1]
          #p response_json["+matrix_x"]
          if stack[1] == response_json["+matrix_x"].to_i
            #p "found a match for square #{response_json["+matrix_x"]}"
            stack[0].fill response_json["+message"]
            stack[0].stroke response_json["+message"]
            stack[0].rect(0,0,30,30)
          end
        end
      end
    end
  end

  def ping_loop(message)
    loop do
      sleep 30
      p "Sending ping, I am: #{message.me}"
      message.body = {"_to"=>"208.68.163.247:42424", "_line" => message.line, "_br"=>message.br}.to_json
      message.send_message
    end
  end

  def start_udpserver
    p "Starting server"
    socket = UDPSocket.new
    p "binding server"
    p socket.bind("0.0.0.0",0)
    message = UDPMessage.new(socket)
    message.hostname = "telehash.org"
    message.port = 42424
    message.body = {"+end"=>"38666817e1b38470644e004b9356c1622368fa57"}.to_json
    p "sending message"
    p message.send_message
    counter = 1
    
    loop do
      p "waiting for message"
      response, addr = socket.recvfrom(50000000)
      message.br += response.size
      response_json = JSON.parse(response)
      p response_json
      line = nil
      if response_json.has_key?("_ring")
        line = response_json["_ring"]
        message.me = response_json["_to"]
        message.body = {".tap"=>[{"has" => ["+key"]}],"_line"=>line, "_to"=>"208.68.163.247:42424"}.to_json
        message.line = line
        Thread.new do
          ping_loop(message)
        end if counter == 1
        
        p "Sending tap"
        message.send_message
        counter += 1
      end
  
      yield response_json
      
    end
    rescue => e
      p e
      puts e.backtrace
  end
  

  $stacks = []
  Thread.new do
    start_udpserver do |response_json|
      drawer(response_json)
    end
  end

  stacker

end

