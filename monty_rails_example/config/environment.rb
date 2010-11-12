# Load the rails application
require File.expand_path('../application', __FILE__)

# Setup Monty
$: << File.expand_path('../../../monty_core/lib/ruby', __FILE__)

# Initialize the rails application
MontyRailsExample::Application.initialize!

#
require 'monty/core'
require 'monty/core/rails_support'

begin
  es = Monty::Core::ExperimentSet.new
  e = es.create_experiment(:name => "Title")
  # e.website = "monty_rails_example"
  e.uri_pattern = "/**"
  e.input_name = :request_id
  e.priority = 1

  r1 = e.create_rule(:change_content, :name => "r1",
                     :path => "//title",
                     :content => "TEST TITLE 1"
                     )
  r2 = e.create_rule(:change_content, :name => "r2",
                     :path => "//title",
                     :content => "TEST TITLE 2"
                     )

  p1 = e.create_possibility(:name => "A", :weight => 1)
  p2 = e.create_possibility(:name => "B", :weight => 1)
  e[p2, r1] = true
  p3 = e.create_possibility(:name => "C", :weight => 1)
  e[p3, r2] = true


  e = es.create_experiment(:name => "Hello Color")
  # e.website = "monty_rails_example"
  e.uri_pattern = "/**"
  e.input_name = :request_id
  e.priority = 2

  r1 = e.create_rule(:change_class, :name => "r1",
                     :path => "id('hello')",
                     :css_class => "hello red"
                     )
 
  p1 = e.create_possibility(:name => "A", :weight => 1)
  p2 = e.create_possibility(:name => "B", :weight => 1)
  e[p2, r1] = true


  ####################################################################
  # Debugging
  #
  if true
    $stderr.puts "Monty XSL ==============================="
    xsl = Monty::Core::Xsl.new
    gen = Monty::Core::XslGenerator.new(:output => xsl)
    input = gen.input = Monty::Core::Input.new
    input.uri = '/'
    input.seeds[:request_id] = 0
    $stderr.puts "Experiments = #{es.experiments.map{|x| x.name}.inspect}"
    $stderr.puts "Applicable Experiments = #{es.applicable_experiments(input).map{|x| x.name}.inspect}"
    gen.generate(es)
    $stderr.write xsl.data
    $stderr.puts "========= ==============================="
    p = Monty::Core::XslProcessor.new(:xsl => xsl)
    errors = p.validate_xsl
    $stderr.puts "Errors = #{errors.inspect}"
  end

  ####################################################################
  # Hooks
  #

  es.class.get_proc = lambda do ||
    es
  end

  $global_request_id = 0
  Monty::Core::Processor.configure do | p |
    p.debug = false

    p.before_process = lambda do | p |
      # $stderr.puts "   before_process"
      p.request.session[:request_id] = ($global_request_id += 1)
    end

    # FIXME: remove _proc.
    p.input_setup_proc = lambda do | p |
      p.input.seeds[:request_id] = p.request.session[:request_id]
      p.input.website = "monty_rails_example"
    end

=begin
    p.before_process_input = lambda do | p |     
    end
=end

    p.after_process_input = lambda do | p |
      ps = p.input.applied_possibilities
      ps = ps.map{|pos| "#{pos.experiment.name}::#{pos.name}"} * ", "
      $stderr.puts "  Monty Request: #{p.input.seeds[:request_id]}: #{p.request.url}: #{ps}"
    end
  end
end

Monty::Core::RailsSupport.activate!

