require 'pry'
require 'polynomial'



class Polynomial
  def latex(base=10)
    @coefs.map{|s| s.to_i.abs}.each_with_index
    .map{|s, i| s==0? "" : (s==1 ? "x^{#{i}}" : "#{format_number(s, base)}x^{#{i}}") }
    .reject{|s| s==""}.reverse
    .map{|s| s=="x^{0}" ? "1" : s}
    .map{|s| s=="x^{1}" ? "x" : s}
    .join(" + ")
  end

  def to_hex
    @coefs.reverse.map{|s| s.abs.to_i % 2}.join.to_i(2).to_s(16).upcase
  end

  def format_number(s, base)
    if base==10
      s.to_s(base)
    else
      "(#{s.to_s(base).upcase})_{#{base}}"
    end
  end

  def division_mod2(p)
    zero_array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    result = Polynomial.new(zero_array.dup)
    current = Polynomial.new(coefs)

    loop do
      c = find_term_coef(current.coefs, p.coefs)
      if c.nil?
        return [result, current]
      else
        tmp = zero_array.dup
        tmp[c] = 1
        new_result_coefs = result.coefs.dup + zero_array.dup
        new_result_coefs[c] = 1
        result = Polynomial.new(new_result_coefs)
        n = Polynomial.new(tmp)
        current = Polynomial.new(((n * p) + current).coefs.map{|s| s % 2})
      end
    end

  end

  def multiply_mod2(p)
    Polynomial.new((self.dup * p).coefs.map{|s| s % 2})
  end

  private

  def find_term_coef(ca, cb)
    greater_ca = ca.each_with_index.map{|s, i| (s>0 ? 1 : 0)*i}.max
    greater_cb = cb.each_with_index.map{|s, i| (s>0 ? 1 : 0)*i}.max
    (greater_ca < greater_cb) ? nil : greater_ca - greater_cb
  end
end

class GF
  attr_reader :value
  def initialize(hex_value)
    @hex = hex_value.to_i(16)
  end

  def value
    @hex
  end

  def as_byte
    @as_byte ||= @hex.to_s(2).rjust(8, "0")
  end

  def coef
    @coef ||= as_byte.split("").map{|s| s.to_i}
  end

  def polynomial
    @polynomial ||= Polynomial.new(*coef.reverse)
  end


  def multiply(gf, show=false)
    mx = GF.new("11B")
    result = polynomial * gf.polynomial
    result_mod_2 = Polynomial.new(result.coefs.map{|s| s % 2})
    total = result_mod_2.division_mod2(mx.polynomial).last
    ltx = total.coefs.map{|s| s.to_i.abs}.reverse.join.to_i(2).to_s(16)
    return total unless show
    puts "$(#{polynomial.latex}) \\otimes (#{gf.polynomial.latex})$ mod $2$\\\\"
    puts "$\\Rightarrow (#{result.latex})$ mod $2$\\\\"
    puts "$\\Rightarrow #{result_mod_2.latex}$\\\\"
    puts "E então fazemos\\\\"
    puts "$#{result_mod_2.latex}$ mod $#{mx.polynomial.latex}$\\\\"
    puts "$\\Rightarrow #{total.latex}$\\"
    puts "$\\Rightarrow  (#{ltx})_{16}$\\\\"
    total
  end
end

class GF32
  def initialize(hex_value)
    @hex_value ||= hex_value
  end

  def coef
    h = @hex_value
    @coef ||= [h[0..1], h[2..3], h[4..5], h[6..7]]
  end

  def polynomial
    @polynomial ||= Polynomial.new(*coef.map{|s| s.to_i(16)}.reverse)
  end

  def multiply(gf, show=false)
    c1 = coef.reverse.map{|s| GF.new(s)}
    c2 = gf.coef.reverse.map{|s| GF.new(s)}
    terms = []
    c1.each_with_index do |a, i|
      c2.each_with_index do |b, j|
        terms << [a, b, i+j]
      end
    end
    terms.sort!{|a, b| b.last<=>a.last}
    puts terms.map{|s| "(#{s[0].value.to_s(16).upcase})_{16}(#{s[1].value.to_s(16).upcase})_{16}x^{#{s.last}}"}
      .join(" + ")
    puts
    terms2 = terms.map{|s| [s[0].multiply(s[1]), s.last]}
    terms2.map!{|s| [s.first.to_hex, s.last]}
    puts terms2.map{|s| "(#{s[0]})_{16}x^{#{s.last}}"}.join(" + ")
    terms3 = [0, 0, 0, 0, 0, 0, 0]
    terms2.each do |s|
      terms3[s.last] = terms3[s.last] ^ s.first.to_i(16)
    end
    puts "\\Rightarrow " + terms3.each_with_index.map{|s, i| "(#{s.to_s(16).upcase})_{16}x^{#{i}}"}.reverse.join(" + ")
    Polynomial.new(terms3)
  end
end
puts; puts; puts;


puts "Ex 0 (confirmando valores)"
puts "=================="
a = GF.new("45")
b = GF.new("0A")
a.multiply(b, true)
puts
puts
#
puts "Ex 2.1"
puts "=================="
a = GF.new("47")
b = GF.new("29")
a.multiply(b, true)
puts
puts
puts "Ex 2.2"
puts "=================="
a = GF.new("7C")
b = GF.new("4A")
a.multiply(b, true)
puts
puts
#



puts "Ex 3.1"
puts "=================="
a = GF32.new("3D7656B2")
b = GF32.new("66A73921")
r =  a.multiply(b)
m = Polynomial.new(1, 0, 0, 0, 1)
puts "A(x) \\otimes B(x) mod M (x) = (#{r.latex(16)}) mod #{m.latex} \\"
puts "\\Rightarrow #{(r % m).latex(16)}\\"

puts; puts

puts "Ex 3.2"
puts "=================="
a = GF32.new("D7158891")
b = GF32.new("35EE1F44")
r =  a.multiply(b)
puts "A(x) \\otimes B(x) mod M (x) = (#{r.latex(16)}) mod #{m.latex} \\"
puts "\\Rightarrow #{(r % m).latex(16)}\\"



puts; puts; puts
puts "Ex 4.1"

cx = GF32.new("03010102")
cxi = GF32.new("0B0D090E")

a = GF32.new("24A656B7")
r1 =  a.multiply(cx)
puts "\\noindent \\Rightarrow #{(r1 % m).latex(16)}\\"

puts "Escrevendo o cálculo da inversa: \\\\"
r2 =  a.multiply(cxi)
puts "\\Rightarrow #{(r2 % m).latex(16)}\\\\"



puts; puts; puts
puts "Ex 4.2"


a = GF32.new("99D10F20")
r1 =  a.multiply(cx)
puts "\\noindent \\Rightarrow #{(r1 % m).latex(16)}\\\\"

puts "Escrevendo o cálculo da inversa: \\\\"
r2 =  a.multiply(cxi)
puts "\\noindent \\Rightarrow #{(r2 % m).latex(16)}\\\\"
