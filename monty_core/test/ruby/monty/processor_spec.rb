require 'monty/core'

require 'monty/core/processor'

describe "Monty::Core::Processor" do
  def with_experiment_set_and_input
      get_proc_save = Monty::Core::ExperimentSet.get_proc
      config_proc_save = Monty::Core::Processor.configure_proc

      process_config_called = nil
      Monty::Core::Processor.configure do | p |
        process_config_called += 1
      end

      es = Monty::Core::ExperimentSet.new

      #########################################################

      e1 = es.create_experiment(:name => "e1")
      e1.website = 'http://test.com'
      e1.uri_pattern = "https?://test.com/**"
      e1.priority = 1
      e1.enabled = true
      
      r1 = e1.create_rule(:change_content, 
                          :name => "e1.r1", 
                          :path => "//title", 
                          :content => "TEST TITLE"
                          )
      p1 = e1.create_possibility(:name => "e1.A", :weight => 1)
      e1[p1, r1] = true

      #########################################################

      e2 = es.create_experiment(:name => "e2")
      e2.website = 'http://test.com'
      e2.uri_pattern = "https?://test.com/test_page.html"
      e2.priority = 2
      e2.enabled = true
      
      r1 = e2.create_rule(:change_content, 
                          :name => "e2.r1", 
                          :path => "//title", 
                          :content => "TEST TITLE 2"
                          )
      r2 = e2.create_rule(:change_attribute, 
                          :name => "e2.r2",
                          :path => "//*[@id='1']",
                          :attribute_name => :style,
                          :attribute_value => 'color: red;'
                          )

      p1 = e2.create_possibility(:name => "e2.A", :weight => 1)
      e2[p1, r1] = true
      e2[p1, r2] = true

      #########################################################

      Monty::Core::ExperimentSet.get_proc = lambda { | | es }

      #########################################################

      input = Monty::Core::Input.new(:content_type => 'text/html')
      input.website = 'http://test.com'
      input.session_id = '1234'
      input.body = <<'END'
<html>
  <head>
     <title>Original Title</title>
  </head>
  <body>
    <div id="1">some text</div>
  </body>
</html>
END
      input.overridden?.should == false

      process_config_called = 0

      p = Monty::Core::Processor.new(:input => input)
      p.experiment_set.should == es
      p.experiment_set.experiments.size.should == 2

      process_config_called.should == 1

    yield es, input, p, e1, e2
    
  ensure
    Monty::Core::ExperimentSet.get_proc = get_proc_save
    Monty::Core::Processor.configure_proc = config_proc_save
  end

  it 'should handle inapplicable URI' do
    with_experiment_set_and_input do | es, input, p, e1, e2 |

      p.input.uri = 'http://void.com/ineligible_page.html'
      (e1.uri_pattern === p.input.uri).should == false
      e1.active?(p.input).should == true
      e1.applicable?(p.input).should == false

      (e2.uri_pattern === p.input.uri).should == false
      e2.active?(p.input).should == true
      e2.applicable?(p.input).should == false

      es.active_experiments(p.input).size.should == 2
      es.applicable_experiments(p.input).size.should == 0
      p.is_active?.should == false

    end
  end

  it 'should handle partially applicable URI' do
    with_experiment_set_and_input do | es, input, p, e1, e2 |
      p.input.uri = 'http://test.com/main.html'
      (e1.uri_pattern === p.input.uri).should == true
      e1.active?(p.input).should == true
      e1.applicable?(p.input).should == true

      (e2.uri_pattern === p.input.uri).should == false
      e2.active?(p.input).should == true
      e2.applicable?(p.input).should == false

      es.active_experiments(p.input).size.should == 2
      es.applicable_experiments(p.input).size.should == 1
      p.is_active?.should == true

    end
  end

  it 'should handle applicable URI' do
    with_experiment_set_and_input do | es, input, p, e1, e2 |

      p.input.uri = 'http://test.com/test_page.html'
      (e1.uri_pattern === p.input.uri).should == true
      e1.active?(p.input).should == true
      e1.applicable?(p.input).should == true

      (e2.uri_pattern === p.input.uri).should == true
      e2.active?(p.input).should == true
      e2.applicable?(p.input).should == true

      es.active_experiments(p.input).size.should == 2
      es.applicable_experiments(p.input).size.should == 2
      p.is_active?.should == true

      p.process_input!

      p.input.applied_possibilities.size.should == 2
      p.input.applied_possibilities.map{|x| x.name}.include?("e1.A").should == true
      p.input.applied_possibilities.map{|x| x.name}.include?("e2.A").should == true

      # require 'pp'; pp p.input.experiment_parameter_values

      p.input.experiment_parameter_values.keys.size.should == 2
      p.input.experiment_parameter_values.values.each do | h |
        h.keys.size.should == 1
        h.each do | k, v |
          k.class.should == Symbol
          v.class.should == Float
        end
      end
      p.input.body.should =~ %r{<title>TEST TITLE 2</title>}
      p.input.body.should =~ %r{<div id="1" style="color: red;">some text</div>}
    end
  end

  it 'should handle forced possibilities' do
    with_experiment_set_and_input do | es, input, p, e1, e2 |

      p.input.uri = 'http://test.com/test_page.html'
      p.input.query_parameters = { '_monty_possibility' => "e1:e1.A" }

      (e1.uri_pattern === p.input.uri).should == true
      e1.active?(p.input).should == true
      e1.applicable?(p.input).should == true

      (e2.uri_pattern === p.input.uri).should == true
      e2.active?(p.input).should == true
      e2.applicable?(p.input).should == true

      es.active_experiments(p.input).size.should == 2
      es.applicable_experiments(p.input).size.should == 2
      p.is_active?.should == true

      p.process_input!

      p.input.overridden?.should == true
      p.input.applied_possibilities.size.should == 1
      p.input.applied_possibilities.map{|x| x.name}.include?("e1.A").should == true

      # require 'pp'; pp p.input.experiment_parameter_values

      p.input.experiment_parameter_values.keys.size.should == 2
      p.input.experiment_parameter_values.values.each do | h |
        h.keys.size.should == 1
        h.each do | k, v |
          k.class.should == Symbol
          v.class.should == Float
        end
      end
      p.input.body.should =~ %r{<title>TEST TITLE</title>}
      p.input.body.should_not =~ %r{<div id="1" style="color: red;">some text</div>}

    end
  end
end # describe

