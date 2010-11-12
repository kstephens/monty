require 'monty/core'
require 'benchmark'

describe "Monty::Core::XslGenerator" do
  attr_accessor :es, :e, :input
  attr_accessor :p

  before(:each) do
    @xsl = nil
    @p = { }
    generate_experiment!
  end

  after(:all) do
    unless ENV['KEEP_FILES']
      File.unlink(xsl.xml_file) rescue nil
      File.unlink(xsl.xsl_file) rescue nil
    end
  end

  def generate_experiment!
    self.es = Monty::Core::ExperimentSet.new
    e = es.create_experiment(:name => File.basename(__FILE__))
    e.enabled = true
    e.uri_pattern = "http://test.com/test.html"

    p[:A] = 
    a = e.create_possibility(:name => "A", 
                             :weight => 1)
    

    p[:B] =
    b = e.create_possibility(:name => "B", 
                             :weight => 1)

    p[:C] =
    c = e.create_possibility(:name => "C", 
                             :weight => 1)
    
    r1 = e.create_rule(:change_content,
                       :name => 'r1',
                       :path => "//title",
                       :content => 'TITLE 1')

    r2 = e.create_rule(:change_content,
                       :name => 'r2',
                       :path => "//title",
                       :content => 'TITLE 2')

    e[a, r1] = false
    e[a, r2] = false

    e[b, r1] = true
    e[b, r2] = false

    e[c, r1] = false
    e[c, r2] = true

    a.identity?.should == true
    b.identity?.should == false
    c.identity?.should == false

    self.e = e
  end

  def generate_input!
    input = Monty::Core::Input.new
    input.session_id = '1234'
    input.uri = 'http://test.com/test.html'
    input.body = <<"END"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <title>TITLE 0</title>
  </head>
  <body>
    <!-- COMMENT 1 -->
  </body>
</html>
END
    @original_body = input.body.dup.freeze

    self.input = input
  end

  def input
    generate_input! unless @input
    @input
  end

  def xsl
    @@xsl ||= false
    unless @@xsl
      @@xsl = Monty::Core::Xslt.new
      gen = Monty::Core::XsltGenerator.new
      gen.output = @@xsl
      gen.generate e
      if false
        $stderr.puts "xsl======"
        $stderr.write @@xsl.data
        $stderr.puts "========="
      end
    end
    @@xsl
  end
  
  def process x
    result = nil
    Benchmark.bm(40) do | bm |
      [ 
       false, 
       # true,
      ].each do | use_experiment_xsl |
        opts = { :use_experiment_xsl => use_experiment_xsl }
        bm.report("#{x} #{opts.inspect}") do 
          poss = p[x] || raise("unknown #{x.inspect}")

          generate_input!
          input.force_possibility! poss

          p = Monty::Core::Processor.new({
                                           :experiment_set => es, 
                                           :input => input,
                                           # :debug_xsl => true,
                                         }.merge(opts))
          p.logger = nil
          p.process_input!
          p.error.should == nil
          result = p.input.body

          yield result
        end
      end
    end
    result
  end

  it "should generate xsl" do
    Benchmark.bm(40) do | bm |
      bm.report("xsl generation") do
        xsl
      end

      bm.report("validate_xsl") do
        processor = xsl.processor
        errors = processor.validate_xsl
        # $stderr.puts "errors = #{errors.inspect}"
        errors.should == nil
      end
    end
  end

  it "should handle Possibility A" do
    process(:A) do | r |
      cmp_diff :A, r, @original_body
    end
  end

  it "should handle Possiblity B" do
    process(:B) do | r |
      cmp_diff :B, r, @original_body.sub(%r{<title>.*?</title>}, "<title>TITLE 1</title>")
    end
  end

  it "should handle Possibility C" do
    process(:C) do | r |
      cmp_diff :C, r, @original_body.sub(%r{<title>.*?</title>}, "<title>TITLE 2</title>")
    end
  end


  ####################################################################


  def cmp_diff name, a, b
    a = a.gsub(/^\s+|\s+$/, '')
    b = b.gsub(/^\s+|\s+$/, '')
    a = a.sub(/^<!DOCTYPE .*?$/m, '<!DOCTYPE ...>')
    b = b.sub(/^<!DOCTYPE .*?$/m, '<!DOCTYPE ...>')

    if true # ignore DOCTYPE presense
      a = a.sub(/\A<!DOCTYPE \.\.\.>\n/, '')
      b = b.sub(/\A<!DOCTYPE \.\.\.>\n/, '')
    end

    return if a == b
    require 'tempfile'

    Tempfile.new("a") do | af |
      Tempfile.new("b") do | bf |
        af.write a
        af.flush
        bf.write b
        bf.flush

        cmd = "diff -u #{af.path} #{bf.path}"
        $stderr.puts "#{cmd}"
        system(cmd)
      end
    end

    $stdout.puts "\n=======================\nPossibility #{name}:"
    $stdout.puts "\nexpected: #{b.size} size"
    $stdout.puts b

    $stdout.puts "\ngiven: #{a.size} size"
    $stdout.puts a

    a.should == b
  end
end # describe


