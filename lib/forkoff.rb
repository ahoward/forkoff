require 'thread'

module Forkoff
  def version
    '1.1.1'
  end

  def default
    @default ||= { 'processes' => 2 }
  end

  def pipe
    'pipe'
  end

  def file 
    'file'
  end

  def pid
    @pid ||= Process.pid
  end

  def ppid
    @ppid ||= Process.ppid
  end

  def tid
    Thread.current.object_id.abs
  end

  def hostname
    require 'socket'
    @hostname ||= (Socket.gethostname rescue 'localhost.localdomain')
  end

  def tmpdir
    require 'tmpdir'
    @tmpdir ||= Dir.tmpdir
  end

  def tmpdir= tmpdir
    @tmpdir = tmpdir.to_s
  end

  def tmpfile &block
    basename = [hostname, pid, ppid, tid, rand].join('-') 
    tmp = File.join(tmpdir, basename)

    fd = nil
    flags = File::CREAT|File::EXCL|File::RDWR

    42.times do
      begin
        fd = open tmp, flags
        break
      rescue Object
        sleep rand
      end
    end
    raise Error, "could not create tmpfile" unless fd

    if block
      begin
        return block.call(fd)
      ensure
        fd.close unless fd.closed? rescue nil
        FileUtils.rm_rf tmp rescue nil
      end
    else
      return fd
    end
  end

  def pipe_result *args, &block
    r, w = IO.pipe
    pid = fork

    unless pid
      r.close
      result =
        begin
          block.call(*args)
        rescue Object => e
          e
        end
      w.write( Marshal.dump( result ) )
      w.close
      exit!
    end

    w.close
    data = ''
    while(( buf = r.read(8192) ))
      data << buf
    end
    result = Marshal.load( data )
    r.close
    Process.waitpid pid
    return result
  end

  def file_result *args, &block
    tmpfile do |fd|
      pid = fork

      unless pid
        result =
          begin
            block.call(*args)
          rescue Object => e
            e
          end
        fd.write( Marshal.dump( result ) )
        exit!
      end

      Process.waitpid pid
      fd.rewind
      data = fd.read
      result = Marshal.load( data )
      return result
    end
  end

  class Error < ::StandardError; end

  extend self

  STRATEGIES = Hash.new do |h, key|
    strategy = key.to_s.strip.downcase.to_sym
    raise ArgumentError, "strategy=#{ strategy.class }(#{ strategy.inspect })" unless h.has_key?(strategy)
    h[key] = h[strategy]
  end

  STRATEGIES.merge!(
    :pipe => :pipe_result,
    :file => :file_result
  )

end

module Enumerable 
  def forkoff options = {}, &block
    options = { 'processes' => Integer(options) } unless Hash === options
    n = Integer( options['processes'] || options[:processes] || Forkoff.default['processes'] )
    strategy = options['strategy'] || options[:strategy] || :pipe
    strategy_method = Forkoff::STRATEGIES[strategy]
    q = SizedQueue.new(n)
    result_sets = Array.new(n){ [] }

    #
    # consumers
    #
      consumers =
        result_sets.map do |set|
          Thread.new do
            Thread.current.abort_on_exception = true

            loop do
              args, index = q.pop
              break if index.nil?

              result = Forkoff.send( strategy_method, *args, &block )

              set.push( [result, index] )
            end

            set.push( :done )
          end
        end

    #
    # producers
    #
      producer = 
        Thread.new do
          Thread.current.abort_on_exception = true
          each_with_index do |args, i|
            q.push( [args, i] )
          end
          n.times do |i|
            q.push( :done )
          end
        end

    #
    # wait for all consumers to complete
    #
      consumers.each do |t|
        t.value
      end

    #
    # gather results
    #
      returned = []

      result_sets.each do |set|
        set.each do |result, index|
          break if index.nil?
          returned[index] = result
        end
      end

      returned
  end

  alias_method 'forkoff!', 'forkoff'
end
