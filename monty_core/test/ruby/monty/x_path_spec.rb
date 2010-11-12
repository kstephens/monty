require 'monty/core'

require 'monty/core/x_path'

describe "Monty::Core::XPath" do
  it "should validate" do
    p = Monty::Core::XPath.new(:string => "//dummy")
    (p.errors).should == [ ]
    (p.valid?).should == true

    p = Monty::Core::XPath.new(:string => "//dummy[@id='something']")
    (p.errors).should == [ ]
    (p.valid?).should == true

    p = Monty::Core::XPath.new(:string => "//dummy[@id='""']")
    (p.errors).should == [ ]
    (p.valid?).should == true
  end

  it "should invalidate" do
    p = Monty::Core::XPath.new
    (p.errors).grep(/NULL pattern/).should_not == nil
    (p.valid?).should == false

    p = Monty::Core::XPath.new(:string => nil)
    (p.errors).grep(/NULL pattern/).should_not == nil
    (p.valid?).should == false

    p = Monty::Core::XPath.new(:string => '')
    (p.errors).grep(/NULL pattern/).should_not == nil
    (p.valid?).should == false

    p = Monty::Core::XPath.new(:string => '   ')
    (p.errors).grep(/NULL pattern/).should_not == nil
    (p.valid?).should == false

    p = Monty::Core::XPath.new(:string => "  #8()*AS()*)S")
    (p.errors).grep(/NULL pattern/).should == [ ]
    (p.errors).grep(/Name expected/).should_not == nil
    (p.valid?).should == false
  end
end

