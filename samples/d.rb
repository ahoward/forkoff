# forkoff supports two strategies of reading the result from the child: via
# pipe (the default) or via file.  you can select which to use using the
# :strategy option.
#

  require 'forkoff'

  %w( hey you guys ).forkoff :strategy => :file do |word|
    puts "#{ word } from #{ Process.pid }"
  end
