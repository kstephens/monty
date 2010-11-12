# TODO: Rename to xsl_generator_spec.rb
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
    
    p[:D] =
    d = e.create_possibility(:name => "D", 
                             :weight => 1)

    r1 = e.create_rule(:change_class,
                       :name => 'r1',
                       :path => "id('1')")
    r1.css_class = "class1"

    r2 = e.create_rule(:change_content,
                       :name => 'r2',
                       :path => "//div[@id='2']")
    r2.content = Monty::Core::Content.new
    r2.content.data = "<h1>NEW CONTENT</h1>"

    r3 = e.create_rule(:swap_content,
                       :name => 'r3',
                       :path => "//*[@id='3']", 
                       :path_other => "//*[@id='4']")
    
    r4 = e.create_rule(:delete,
                       :name => 'r4',
                       :path => "id('5')")

    r5 = e.create_rule(:change_style,
                       :name => 'r5',
                       :path => "id('6')", 
                       :css_style => "color: red;")

    e[a, r1] = false
    e[a, r2] = false
    e[a, r3] = false
    e[a, r4] = false
    e[a, r5] = false

    e[b, r1] = true
    e[b, r2] = true
    e[b, r3] = false
    e[b, r4] = false
    e[b, r5] = false

    e[c, r1] = false
    e[c, r2] = false
    e[c, r3] = true
    e[c, r4] = false
    e[c, r5] = false

    e[d, r1] = false
    e[d, r2] = false
    e[d, r3] = true
    e[d, r4] = true
    e[d, r5] = true

    a.identity?.should == true
    b.identity?.should == false
    c.identity?.should == false
    d.identity?.should == false

    input = Monty::Core::Input.new
    input.session_id = '1234'
    input.uri = 'http://test.com/test.html'
    input.body = <<"END"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    //<![CDATA[
    
    SomeObject.Variable = true;
    
    //]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1">div1</div>
    <div id="2" attr="attr2">div2</div>
    <div id="3" attr="attr3">div3</div>
    <div id="4" attr="attr4">div4</div>
    <div id="5" attr="attr5">div5</div>
    <div id="6" attr="attr6">div6</div>

    <div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
    @original_body = input.body.dup.freeze

    self.e = e
    self.input = input
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
      bm.report(x.to_s) do 
        poss = p[x] || raise("unknown #{x.inspect}")
        input.force_possibility! poss
        p = Monty::Core::Processor.new(:experiment_set => es, :input => input)
        p.logger = nil
        p.process_input!
        p.error.should == nil
        result = p.input.body
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

  it "should handle Possibility A (invalid param)" do
    r = nil

    Benchmark.bm(40) do | bm |
      bm.report("A (invalid param)") do 
        r =
          # xsl.processor(:use_xsltproc => true, :debug => true).
          xsl.processor.
          apply(input.body, { :param_1 => -1.0 })
      end
    end

    cmp_diff :A, r, @original_body
  end

  it "should handle Possibility A" do
    r = process(:A)
    cmp_diff :A, r, @original_body
  end

  it "should handle Possiblity B" do
    r = process(:B)
    cmp_diff :B, r, <<'END'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    //<![CDATA[
    
    SomeObject.Variable = true;
    
    //]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1" class="class1">div1</div>
    <div id="2" attr="attr2"><h1>NEW CONTENT</h1></div>
    <div id="3" attr="attr3">div3</div>
    <div id="4" attr="attr4">div4</div>
    <div id="5" attr="attr5">div5</div>
    <div id="6" attr="attr6">div6</div>

    <div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
  end

  it "should handle Possibility C" do
    r = process(:C)
    cmp_diff :C, r, <<'END'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    //<![CDATA[
    
    SomeObject.Variable = true;
    
    //]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1">div1</div>
    <div id="2" attr="attr2">div2</div>
    <div id="3" attr="attr3">div4</div>
    <div id="4" attr="attr4">div3</div>
    <div id="5" attr="attr5">div5</div>
    <div id="6" attr="attr6">div6</div>

    <div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
  end


  it "should handle Possibility D" do
    r = process(:D)
    cmp_diff :D, r, <<'END'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    //<![CDATA[
    
    SomeObject.Variable = true;
    
    //]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1">div1</div>
    <div id="2" attr="attr2">div2</div>
    <div id="3" attr="attr3">div4</div>
    <div id="4" attr="attr4">div3</div>
    <div id="6" attr="attr6" style="color: red;">div6</div><div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
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


