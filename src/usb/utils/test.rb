m = 8 * 1024 * 1024 * 4#MB
n = 1500000

k = (Math.log(2.0) * m / n).round
p = (1 - Math.exp(-k.to_f * n / m)) ** k

puts "k: #{k}, p: #{p}" 

