require 'monty/core'

require 'monty/core/uri_pattern'

describe "Monty::Core::UriPattern" do
  it "should match all URIs if its #string is empty." do
    p = Monty::Core::UriPattern.new(:string => "")
    p.patterns.empty?.should == true
    # $stderr.puts p.to_rx.inspect
    (p === nil).should == true
    (p === '').should == true
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == true
  end

  it "should match all URIs if its #string is nil." do
    p = Monty::Core::UriPattern.new(:string => nil)
    p.patterns.empty?.should == true
    # $stderr.puts p.to_rx.inspect
    (p === nil).should == true
    (p === '').should == true
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == true
  end

  it "should match simple uris" do
    p = Monty::Core::UriPattern.new(:string => "https://foobar.html")
    # $stderr.puts p.to_rx.inspect
    (p === nil).should == false
    (p === '').should == false
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == false
  end

  it "should match ? as a regexp" do
    p = Monty::Core::UriPattern.new(:string => "https?://foobar.html")
    # $stderr.puts p.to_rx.inspect
    (p === nil).should == false
    (p === '').should == false
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == true
  end

  it "should match * as any non-/ characters" do
    p = Monty::Core::UriPattern.new(:string => "https?://foobar*.html")
    # $stderr.puts p.to_rx.inspect
    (p === nil).should == false
    (p === '').should == false
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == true
    (p === 'https://foobara.html').should == true
    (p === 'http://foobarab.html').should == true
    (p === 'https://foobar/.html').should == false
    (p === 'http://foobar/ab.html').should == false
  end

  it "should match ** as any characters" do
    p = Monty::Core::UriPattern.new(:string => "https?://foobar**.html")
    # $stderr.puts p.to_rx.inspect
    (p === nil).should == false
    (p === '').should == false
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == true
    (p === 'https://foobara.html').should == true
    (p === 'http://foobarab.html').should == true
    (p === 'https://foobar/.html').should == true
    (p === 'http://foobar/ab.html').should == true
  end

  it "should handle parsing multiple patterns" do
    p = Monty::Core::UriPattern.new(:string => "https?://foobar.html, https?://baz.html?")
    # $stderr.puts p.to_rx.inspect
    (p === '').should == false
    (p === 'https://foobar.html').should == true
    (p === 'http://foobar.html').should == true
    (p === 'https://baz.html').should == true
    (p === 'http://baz.html').should == true
    (p === 'https://baz.htm').should == true
    (p === 'http://baz.htm').should == true
    (p === 'http://asdfkajsdf.htm').should == false
  end
end

