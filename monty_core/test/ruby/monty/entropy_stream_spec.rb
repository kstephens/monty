require 'monty/core'

describe "Monty::Core::EntropyStream" do
  it "should generate integers" do
    s = create_stream

    1000.times do 
      x = s.to_i
      x.should >= 0
      x.should < Monty::Core::EntropyStream::RAW_INT_MAX
    end
  end

  it "should generate floats" do
    s = create_stream

    1000.times do 
      x = s.to_f
      x.should >= 0.0
      x.should <= 1.0
    end
  end

  it "should generate repeatable results" do
    s = create_stream "1234"
    a1 = (0..10).map { | i | s.to_i }
    a1.should == [8570519, 4469708, 1094440, 14972080, 8700481, 5463024, 11146142, 2122019, 2795306, 6648151, 13861864]

    s = create_stream "5678"
    a2 = (0..10).map { | i | s.to_i }
    a2.should == [919817, 9727013, 3629626, 1835343, 16236534, 13445782, 8972906, 9097799, 7680339, 4249796, 7916729]

    a1.should_not == a2
  end

  it "should handle long seeds" do
    s = create_stream("1234" * 128)
    a1 = (0..10).map { | i | s.to_i }
    a1.should == [7424261, 519411, 6927, 288741, 4012195, 10033140, 6311811, 14329841, 12869772, 499657, 3843192]
  end


  it "should generate zeros if seed is nil" do
    s = create_stream(nil)

    1000.times do 
      x = s.to_i
      x.should == 0
    end
  end


  def create_stream seed = ''
    s = Monty::Core::EntropyStream.new(:seed => seed)

    s
  end

end

