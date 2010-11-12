require 'monty/core'
require 'benchmark'

describe "Monty::Core::XslGenerator" do
  attr_accessor :es, :e, :input
  attr_accessor :p

  before(:each) do
    @p = { }
  end

  def experiment_1!
    self.es = Monty::Core::ExperimentSet.new
    e = es.create_experiment(:name => File.basename(__FILE__))
    e.enabled = true
    e.uri_pattern = "http://test.com/test.html"

    p[:A1] = 
    a = e.create_possibility(:name => "A", 
                             :weight => 1)
    
    p[:B1] =
    b = e.create_possibility(:name => "B", 
                             :weight => 1)
    
    p[:C1] =
    c = e.create_possibility(:name => "C", 
                             :weight => 1)
    
    p[:D1] =
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

    self.e = e
  end

  def input_1!
    input = Monty::Core::Input.new
    input.session_id = '1234'
    input.uri = 'http://test.com/test.html'
    input.body = <<"END"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    // <![CDATA[
    
    SomeObject.Variable = true;
    
    // ]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1">div1</div>
    <div id="2" attr="attr2">div2</div>
    <div id="3" attr="attr3"><h3>div3</h3></div>
    <div id="4" attr="attr4"><h4>div4</h4></div>
    <div id="5" attr="attr5">div5</div>
    <div id="6" attr="attr6">div6</div>

    <div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
    @original_body = input.body.dup.freeze

    self.input = input
  end

  ####################################################################

  def experiment_2!
    self.es = Monty::Core::ExperimentSet.new
    e = es.create_experiment(:name => File.basename(__FILE__))
    e.enabled = true
    e.uri_pattern = "http://test.com/test.html"

    p[:A2] = 
    a = e.create_possibility(:name => "A", 
                             :weight => 1)
    

    p[:B2] =
    b = e.create_possibility(:name => "B", 
                             :weight => 1)

    p[:C2] =
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

  def input_2!
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

  ####################################################################

  def process x, input_gen
    result = nil
    Benchmark.bm(40) do | bm |
      [
       false,
       # true,
      ].uniq.each do | use_xsl |
      [ 
       false, 
       # use_xsl,
      ].uniq.each do | use_experiment_xsl |
      
        @opts = opts = { :use_xsl => use_xsl, :use_experiment_xsl => use_experiment_xsl }
        bm.report(@name = "#{x} #{opts.inspect}") do 
          poss = p[x] || raise("unknown #{x.inspect}")

          self.send(input_gen)

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

          input.applied_possibilities.should == [ poss ]

          yield result
        end
      end; end
    end
    result
  end

  it "should handle Possibility A1" do
    experiment_1!
    process(:A1, :input_1!) do | r |
      cmp_diff r, @original_body
    end
  end

  it "should handle Possiblity B1" do
    experiment_1!
    process(:B1, :input_1!) do | r |
      cmp_diff r, <<'END'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    // <![CDATA[
    
    SomeObject.Variable = true;
    
    // ]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1" class="class1">div1</div>
    <div id="2" attr="attr2"><h1>NEW CONTENT</h1></div>
    <div id="3" attr="attr3"><h3>div3</h3></div>
    <div id="4" attr="attr4"><h4>div4</h4></div>
    <div id="5" attr="attr5">div5</div>
    <div id="6" attr="attr6">div6</div>

    <div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
    end
  end

  it "should handle Possibility C1" do
    experiment_1!
    process(:C1, :input_1!) do | r |
      cmp_diff r, <<'END'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    // <![CDATA[
    
    SomeObject.Variable = true;
    
    // ]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1">div1</div>
    <div id="2" attr="attr2">div2</div>
    <div id="3" attr="attr3"><h4>div4</h4></div>
    <div id="4" attr="attr4"><h3>div3</h3></div>
    <div id="5" attr="attr5">div5</div>
    <div id="6" attr="attr6">div6</div>

    <div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
    end
  end


  it "should handle Possibility D1" do
    experiment_1!
    process(:D1, :input_1!) do | r |
      cmp_diff r, <<'END'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
  <head>
    <script src="/javascripts/foo.js" type="text/javascript"></script>
    <script type="text/javascript">
    // <![CDATA[
    
    SomeObject.Variable = true;
    
    // ]]>
    </script>
  </head>
  <body>
    <!-- COMMENT 1 -->
    <div id="0" attr="attr0">div0</div>

    <div id="1" attr="attr1">div1</div>
    <div id="2" attr="attr2">div2</div>
    <div id="3" attr="attr3"><h4>div4</h4></div>
    <div id="4" attr="attr4"><h3>div3</h3></div>
    <div id="6" attr="attr6" style="color: red;">div6</div><div id="7" attr="attr7">div7</div>
    <!-- COMMENT 2 -->
  </body>
</html>
END
    end
  end

  ####################################################################

  it "should handle Possibility A2" do
    experiment_2!
    process(:A2, :input_2!) do | r |
      cmp_diff r, @original_body
    end
  end

  it "should handle Possiblity B2" do
    experiment_2!
    process(:B2, :input_2!) do | r |
      cmp_diff r, @original_body.sub(%r{<title>.*?</title>}, "<title>TITLE 1</title>")
    end
  end

  it "should handle Possibility C2" do
    experiment_2!
    process(:C2, :input_2!) do | r |
      cmp_diff r, @original_body.sub(%r{<title>.*?</title>}, "<title>TITLE 2</title>")
    end
  end


  ####################################################################


  def cmp_diff a_in, b_in
    a = a_in
    b = b_in

    a = a.gsub(/^\s+|\s+$/m, '')
    b = b.gsub(/^\s+|\s+$/m, '')

    a = a.sub(/\A<\!DOCTYPE [^\n]+\n/, "<!DOCTYPE _>\n")
    b = b.sub(/\A<\!DOCTYPE [^\n]+\n/, "<!DOCTYPE _>\n")

    if true # ignore DOCTYPE presense
      a = a.sub(/\A<\!DOCTYPE _>\n/, '')
      b = b.sub(/\A<\!DOCTYPE _>\n/, '')
    end

    if true # ignore meta http-equiv Content-type
      a = a.gsub(%r{<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n}, '')
      b = b.gsub(%r{<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\n}, '')
    end

    if false # FIXME: See hack in xml_parse.rb
      a = a.gsub(%r{<!\[CDATA\[\n//<!\[CDATA\[}, '//<![CDATA[')
      b = b.gsub(%r{<!\[CDATA\[\n//<!\[CDATA\[}, '//<![CDATA[')
      
      a = a.gsub(%r{//\]\]\]\]><!\[CDATA\[>\n\]\]>}, '//]]>')
      b = b.gsub(%r{//\]\]\]\]><!\[CDATA\[>\n\]\]>}, '//]]>')
    end

    return if a == b

    if false
      $stderr.puts "a ==\n#{a_in}"
      $stderr.puts "b ==\n#{b_in}"
    end

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

    $stdout.puts "\n=======================\nCase #{@name}:"
    $stdout.puts "\nexpected: #{b.size} size"
    $stdout.puts b

    $stdout.puts "\ngiven: #{a.size} size"
    $stdout.puts a

    a_in.should == b_in
  end
end # describe


