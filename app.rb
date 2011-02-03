#ShoutOut to @donpdonp for suggesting Shoes for gui
require 'rubygems'

#require 'ezcrypto/signer'
SHOES_APP = File.expand_path(__FILE__)
require 'shoes'
Shoes.setup do
  gem 'ezcrypto'
end
require 'ezcrypto'
require 'ezsig'
require 'digest/sha1'
require 'json'

class Bignum
  def to_bits(num = self)
    num.to_s(2).split(//).inject(0) { |s,i| s + i.to_i }
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

def RSASign(sHashHex, pub, priv) #this function copied from the rsa.js script included in Tom Wu's jsbn library
  #n = new Math_BigInteger(pub,16);
  sMid = "";	fLen = ((pub.size*8) / 4) - sHashHex.length - 6
  #p pub.to_bits
  i = 0
  p "FLEN #{fLen}"
=begin
  fLen.times do |blah|
    sMid += "ff"
    i += 2
  end
=end
  sMid = "f"*82
  p "SMID: #{sMid.length}"
  hPM = "0001" + sMid + "00" + sHashHex #this pads the hash to desired length - not entirely sure whether those 'ff' should be random bytes for security or not
  x = hPM.to_i(16) #turn the padded message into a jsbn BigInteger object
  #$d = new Math_BigInteger($priv,16)
  p "X: #{x}, PRIV: #{priv}, PUB: #{pub}"
  return Math.power_modulo(x,priv,pub) #$x->modPow($d, $n)
end


#key = EzCrypto::Key.generate
#p key
signer = EzCrypto::Signer.generate
#p signer.methods - Object.methods
msg = 'something secret'
sha1 = Digest::SHA1.hexdigest(msg)
#p sha1 #.methods - Object.methods
#n = signer.public_key.n.to_int
#d = signer.private_key.d.to_int
n= 0xcc0f26cd602216e149fe8c2b4027293cd05cd5ccb8720d48a3e50c11c4ce5402cbd3d186e05f5bf15acb078c945f3ca99d0f1b4c7a01722704981afe7ba58f5b
d = 0x880b6df62caa6d90a3d166480b8c504cf029848ce947789dbe4f1d7dd7352c0243dc83e5c7704632b0ad55e9086c11deb7bbda791b59a2eca8da99be6dde6a79
sig = RSASign(sha1, n, d).to_s(16)
telex = {"+key" => n.to_s(16), "_hop" => 1,"+end" => "8bf1cce916417d16b7554135b6b075fb16dd26ce","_to"=>"208.68.163.247:42424", "+sig"=>sig, "+message"=>msg }.to_json

#p signer.public_key.e.to_int
#sig = signer.sign("Happy valentines day mother fuckers")
#p sig.methods - Object.methods
#p sig.class
#p sig.to_i(base=16)
def stacker
  colors = ['#00f','#f00', '#0f0']
  colors.each do |color|
    baz = stack :width => 30, :height => 30 do |this|
      fill color
      stroke color
      foo = self
      click do |b,x,y|
        #alert("clicked on #{color} square")
        p baz
        baz.fill purple
        baz.stroke purple
        baz.rect(0,0,30,30)
      end
      rect(0,0,30,30)
    end
    p "foo"
  end
end
Shoes.app :width => 60, :height => 32 do
  stacker
end
