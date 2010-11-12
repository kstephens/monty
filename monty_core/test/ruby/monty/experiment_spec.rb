require 'monty/core'

describe "Monty::Core::Experiment" do
  attr_accessor :experiment_group
  alias :eg :experiment_group

  it "should be applicable based on enabled." do
    e, input = create_experiment

    e.enabled?.should == true
    eg.enabled?.should == true

    e.enabled = false
    e.applicable?(input).should == false

    e.enabled = true
    e.applicable?(input).should == true
  end

  it "should be applicable based on ExperimentGroup#enabled." do
    e, input = create_experiment

    e.enabled?.should == true
    eg.enabled?.should == true

    eg.enabled = false
    e.applicable?(input).should == false

    eg.enabled = true
    e.applicable?(input).should == true
  end

  it "should be applicable based on time." do
    e, input = create_experiment

    e.start_time.should == nil
    e.end_time.should == nil

    e.applicable?(input).should == true

    eg.start_time = input.now + 10
    eg.end_time   = input.now + 40
    e.applicable?(input).should == false

    eg.start_time = input.now - 10
    eg.end_time   = input.now - 5
    e.applicable?(input).should == false

    eg.start_time = input.now - 10
    eg.end_time = input.now + 10
    e.applicable?(input).should == true
  end

  it "should be applicable based on uri_pattern." do
    e, input = create_experiment

    input.uri = 'http://test.com/test_not_applicable.html'
    e.applicable?(input).should == false

    input.uri = 'http://test.com/test.html'
    e.applicable?(input).should == true
  end

  it "should be applicable based on referrer_pattern." do
    e, input = create_experiment
    e.referrer_pattern = 'https?://other.com/page.html'

    input.uri = 'http://test.com/test.html'
    input.referrer = nil
    e.applicable?(input).should == false

    input.uri = 'http://test.com/test.html'
    input.referrer = 'http://other.com/page.html'
    e.applicable?(input).should == true

    input.uri = 'http://test.com/test.html'
    input.referrer = 'https://other.com/page.html'
    e.applicable?(input).should == true
  end

  it "should be applicable based on website." do
    e, input = create_experiment
    e.website = 'http://test.com'

    input.uri = 'http://test.com/test.html'
    input.website = nil
    e.applicable?(input).should == false

    input.uri = 'http://test.com/test.html'
    input.website = ''
    e.applicable?(input).should == false

    input.uri = 'http://test.com/test.html'
    input.website = 'http://test.com'
    e.applicable?(input).should == true

    input.uri = 'http://test.com/test.html'
    input.website = 'https://test.com'
    e.applicable?(input).should == false
  end

  it "should handle RuleSelection setup." do
    e, input = create_experiment

    e["A", "r1"] = true
    e["A", "r1"].should == true

    e["A", "r2"].should == nil

    e.rule_selections.size.should == 1

    e["B", "r1"].should == nil
    e["B", "r1"] = true
    e["B", "r1"].should == true
   
    e.rule_selections.size.should == 2
  end

  it "should compute probability ranges." do
    e, input = create_experiment

    e.possibilities.size.should == 2
    e.possibilities[0].index.should == 0
    e.possibilities[1].index.should == 1

    e.possibilities[0].weight_range.should == (0 ... 1)
    e.possibilities[1].weight_range.should == (1 ... 3)

    e.possibilities[0].probability_range.should == (0 ... 1.0/3.0)
    e.possibilities[1].probability_range.should == (1.0/3.0 ... 3.0/3.0)
  end


  def create_experiment
    eg = @experiment_group = Monty::Core::ExperimentGroup.new(:name => __FILE__)
    eg.enabled = true
    eg.start_time = eg.end_time = nil

    e = Monty::Core::Experiment.new(:name => __FILE__, :experiment_group => experiment_group)
    e.enabled = true
    e.uri_pattern = "http://test.com/test.html"
    e.uri_pattern.class.should == Monty::Core::UriPattern

    a = e.create_possibility(:name => "A", 
                             :weight => 1)

    b = e.create_possibility(:name => "B", 
                             :weight => 2)

    r1 = e.create_rule(:change_class, :name => 'r1', :path => "//div[@id='1']")
    r1.css_class = "class1"

    input = Monty::Core::Input.new
    input.uri = 'http://test.com/test.html'

    [ e, input ]
  end

end

