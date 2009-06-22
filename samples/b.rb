# for example, this takes only 4 seconds or so to complete (8 iterations
# running in two processes = twice as fast)
#

  require 'forkoff'

  a = Time.now.to_f

  results =
    (0..7).forkoff do |i|
      sleep 1
      i ** 2
    end

  b = Time.now.to_f

  elapsed = b - a

  puts "elapsed: #{ elapsed }"
  puts "results: #{ results.inspect }"
