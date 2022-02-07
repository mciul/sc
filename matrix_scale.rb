#!/usr/bin/env ruby
#
#

require 'rational'

def ratiomidi(r)
  Math.log(1.0/r) / Math.log(2) * 12
end

def delay_symbols(ds)
  ds.map {
    |d| (1/d).to_i
  }.map {
    |i| %w(zero one half third quarter fifth sixth seventh eighth)[i]
  }.map {
    |s| '\\' + s
  }.join ", "
end

delays = [2,3,4,5,6,8].map { |i| Rational(1,i) }
cmbs = (1..6).each_with_object([]) { |count, list| list << delays.combination(count).to_a }.reduce(&:+)
sums = cmbs.map { |c| [c, c.reduce(&:+)] } 

sums.sort_by { |l, s| s }.each do |ds, sum|
  puts "~feedbackPaths[~tonic+#{ratiomidi(sum).round}] = [#{delay_symbols(ds)}] // #{(1/sum)}f = tonic + #{ratiomidi(sum)} semitone"
end
