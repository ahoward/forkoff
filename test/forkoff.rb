$:.unshift('.')
$:.unshift('./lib')
$:.unshift('..')
$:.unshift('../lib')

require('test/unit')
require('forkoff')


class T < Test::Unit::TestCase

# simple usage
#

  def test_0010
    results = [0,1,2].forkoff!{|n| [n, Process.pid]}
    assert_equal(results, results.uniq, 'all ran in a different process')
  end

# it's faster
#
  def test_0020
    n = 4
    strategies = :forkoff, :each

    4.times do
      result = {}

      strategies.each do |strategy|
        a = Time.now.to_f
        (0..4).send(strategy){|i| sleep 0.2}
        b = Time.now.to_f
        elapsed = b - a
        result[strategy] = elapsed
      end

      assert result[:forkoff] < result[:each], 'forkoff is faster than each for long running tasks'
    end
  end

# in case of different execution times for different processes
#
  def test_0030
    a = Time.now.to_f
    (0...4).forkoff(2) do |i|
      sleep i.modulo(2)
    end
    b = Time.now.to_f
    elapsed = b - a
    assert elapsed < 2
  end


end
