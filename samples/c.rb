# forkoff does *NOT* spawn processes in batches, waiting for each batch to
# complete.  rather, it keeps a certain number of processes busy until all
# results have been gathered.  in otherwords the following will ensure that 3
# processes are running at all times, until the list is complete. note that
# the following will take about 3 seconds to run (3 sets of 3 @ 1 second).
#

require 'forkoff'

pid = Process.pid

a = Time.now.to_f

pstrees =
  %w( a b c d e f g h i ).forkoff! :processes => 3 do |letter|
    sleep 1
    { letter => ` pstree -l 2 #{ pid } ` }
  end


b = Time.now.to_f

puts
puts "pid: #{ pid }"
puts "elapsed: #{ b - a }"
puts

require 'yaml'

pstrees.each do |pstree|
  y pstree
end
