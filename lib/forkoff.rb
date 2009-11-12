require 'thread'

module Forkoff
  def version
    '1.1.1'
  end

  def done
    @done ||= Object.new
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
end

module Enumerable 
  def forkoff options = {}, &block
    options = { 'processes' => Integer(options) } unless Hash === options
    n = Integer( options['processes'] || options[:processes] || Forkoff.default['processes'] )
    strategy = options['strategy'] || options[:strategy] || 'pipe'
    q = SizedQueue.new(n)
    results = Array.new(n){ [] }

    #
    # consumers
    #
      consumers = []

      n.times do |i|
        thread =
          Thread.new do
            Thread.current.abort_on_exception = true

            loop do
              value = q.pop
              break if value == Forkoff.done
              args, index = value

              result =
                case strategy.to_s.strip.downcase
                  when 'pipe'
                    Forkoff.pipe_result(*args, &block)
                  when 'file'
                    Forkoff.file_result(*args, &block)
                  else
                    raise ArgumentError, "strategy=#{ strategy.class }(#{ strategy.inspect })"
                end          

              results[i].push( [result, index] )
            end

            results[i].push( Forkoff.done )
          end

        consumers << thread
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
            q.push( Forkoff.done )
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

      results.each do |set|
        set.each do |value|
          break if value == Forkoff.done
          result, index = value
          returned[index] = result
        end
      end

      returned
  end

  alias_method 'forkoff!', 'forkoff'
end
