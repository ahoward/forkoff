# forkoff makes it trivial to do parallel processing with ruby, the following
# prints out each word in a separate process
#

  require 'forkoff'

  %w( hey you ).forkoff!{|word| puts "#{ word } from #{ Process.pid }"}
