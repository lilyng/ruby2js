gem 'minitest'
require 'minitest/autorun'
require 'ruby2js/filter/react'

describe Ruby2JS::Filter::React do
  
  def to_js(string)
    Ruby2JS.convert(string, filters: [Ruby2JS::Filter::React], scope: self)
  end
  
  describe :createClass do
    it "should create classes" do
      to_js( 'class Foo<React; end' ).
        must_equal 'var Foo = React.createClass({displayName: "Foo"})'
    end

    it "should create methods" do
      to_js( 'class Foo<React; def f(); end; end' ).
        must_include 'f: function() {}'
    end
  end

  describe "Wunderbar/JSX processing" do
    it "should create elements for HTML tags" do
      to_js( 'class Foo<React; def render; _a; end; end' ).
        must_include 'return React.createElement("a")'
    end

    it "should create elements for React Components" do
      to_js( 'class Foo<React; def render; _A; end; end' ).
        must_include 'return React.createElement(A)'
    end

    it "should create elements with attributes and text" do
      to_js( 'class Foo<React; def render; _a "name", href: "link"; end; end' ).
        must_include 'return React.createElement("a", {href: "link"}, "name")}})'
    end

    it "should create simple nested elements" do
      to_js( 'class Foo<React; def render; _a {_b}; end; end' ).
        must_include ' React.createElement("a", null, React.createElement("b"))'
    end

    it "should create complex nested elements" do
      result = to_js('class Foo<React; def render; _a {c="c"; _b c}; end; end')

      result.must_include 'React.createElement.apply(React, function() {'
      result.must_include 'var $_ = ["a", null];'
      result.must_include '$_.push(React.createElement("b", null, c));'
      result.must_include 'return $_'
      result.must_include '}())'
    end

    it "should iterate" do
      result = to_js('class Foo<React; def render; _ul list ' + 
        'do |i| _li i; end; end; end')

      result.must_include 'React.createElement.apply(React, function() {'
      result.must_include 'var $_ = ["ul", null];'
      result.must_include 'list.forEach(function(i)'
      result.must_include '{$_.push(React.createElement("li", null, i))}'
      result.must_include 'return $_'
      result.must_include '}())'
    end

    it "should handle text nodes" do
      to_js( 'class Foo<React; def render; _a {_ "hi"}; end; end' ).
        must_include 'return React.createElement("a", null, "hi")'
    end
  end

  describe "class attributes" do
    it "should handle class attributes" do
      to_js( 'class Foo<React; def render; _a class: "b"; end; end' ).
        must_include 'React.createElement("a", {className: "b"})'
    end

    it "should handle className attributes" do
      to_js( 'class Foo<React; def render; _a className: "b"; end; end' ).
        must_include 'React.createElement("a", {className: "b"})'
    end

    it "should handle markaby syntax" do
      to_js( 'class Foo<React; def render; _a.b.c href: "d"; end; end' ).
        must_include 'React.createElement("a", {className: "b c", href: "d"})'
    end

    it "should handle mixed strings" do
      to_js( 'class Foo<React; def render; _a.b class: "c"; end; end' ).
        must_include 'React.createElement("a", {className: "b c"})'
    end

    it "should handle mixed strings and a value" do
      to_js( 'class Foo<React; def render; _a.b class: c; end; end' ).
        must_include 'React.createElement("a", {className: "b " + c})'
    end
  end

  describe "other attributes" do
    it "should handle markaby syntax ids" do
      to_js( 'class Foo<React; def render; _a.b! href: "c"; end; end' ).
        must_include 'React.createElement("a", {id: "b", href: "c"})'
    end

    it "should map for attributes to htmlFor" do
      to_js( 'class Foo<React; def render; _a for: "b"; end; end' ).
        must_include 'React.createElement("a", {htmlFor: "b"})'
    end
  end

  describe "~refs" do
    it "should handle ~ symbols properties" do
      to_js( 'class Foo<React; def method; ~x.text; end; end' ).
        must_include 'this.refs.x.getDOMNode().text'
    end

    it "should handle ~ lvar properties" do
      to_js( 'class Foo<React; def method; text = ~x.text; end; end' ).
        must_include 'text = this.refs.x.getDOMNode().text'
    end

    it "should handle ~ methods" do
      to_js( 'class Foo<React; def method; ~x.remove(); end; end' ).
        must_include 'this.refs.x.getDOMNode().remove()'
    end
  end

  describe "map gvars/ivars/cvars to refs/state/prop" do
    it "should map global variables to refs" do
      to_js( 'class Foo<React; def method; $x; end; end' ).
        must_include 'this.refs.x'
    end

    it "should map instance variables to state" do
      to_js( 'class Foo<React; def method; @x; end; end' ).
        must_include 'this.state.x'
    end

    it "should map setting instance variables to setState" do
      to_js( 'class Foo<React; def method; @x=1; end; end' ).
        must_include 'this.setState({x: 1})'
    end

    it "should map class variables to properties" do
      to_js( 'class Foo<React; def method; @@x; end; end' ).
        must_include 'this.props.x'
    end
  end

  describe "method calls" do
    it "should handle ivars" do
      to_js( 'class Foo<React; def method; @x.(); end; end' ).
        must_include 'this.state.x()'
    end

    it "should handle cvars" do
      to_js( 'class Foo<React; def method; @@x.(); end; end' ).
        must_include 'this.props.x()'
    end

    it "should handle gvars" do
      to_js( 'class Foo<React; def method; $x.(); end; end' ).
        must_include 'this.refs.x()'
    end
  end

  describe 'react calls' do
    it 'should create elements' do
      to_js( 'React.render _Element, document.getElementById("sidebar")' ).
        must_include 'React.createElement(Element)'
    end

    it 'should substitute scope instance variables / props' do
      @data = 5
      to_js( "React.render _Element(data: @data),
        document.getElementById('sidebar')" ).
        must_include 'React.createElement(Element, {data: 5})'
    end
  end

  describe Ruby2JS::Filter::DEFAULTS do
    it "should include React" do
      Ruby2JS::Filter::DEFAULTS.must_include Ruby2JS::Filter::React
    end
  end
end
