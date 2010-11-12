require 'monty/core'

require 'monty/core/config'

class Monty::Core::Config::Test
  attr_accessor :foo, :bar
  def initialize *args
    # $stderr.puts "  Monty::Core::Config::Test#initialize #{args.inspect}"
    @foo = 1
  end
  include Monty::Core::Config
end


class Monty::Core::Config::Test2 < Monty::Core::Config::Test
  attr_accessor :baz
  include Monty::Core::Config
end


describe "Monty::Core::Processor" do
  it "should process a simple Experiment." do
    Monty::Core::Config::Test.configure nil
    Monty::Core::Config::Test2.configure nil

    obj = Monty::Core::Config::Test.new()
    obj.foo.should == 1
    obj.bar.should == nil

    called_1 = called_2 = nil

    Monty::Core::Config::Test.configure do | obj |
      # $stderr.puts " Monty::Core::Config::Test.configure #{obj.inspect}"
      called_1 += 1
      obj.foo = 11
    end

    Monty::Core::Config::Test2.configure = Proc.new do | obj |
      # $stderr.puts " Monty::Core::Config::Test2.configure #{obj.inspect}"
      called_2 += 1
      obj.foo = 21
      obj.bar = 22
      obj.baz = 23
    end

    called_1 = called_2 = 0
    obj = Monty::Core::Config::Test.new()
    called_1.should == 1
    called_2.should == 0
    obj.foo.should == 11
    obj.bar.should == nil

    called_1 = called_2 = 0
    obj = Monty::Core::Config::Test2.new()
    called_1.should == 1
    called_2.should == 1
    obj.foo.should == 21
    obj.bar.should == 22
    obj.baz.should == 23

  end
end

