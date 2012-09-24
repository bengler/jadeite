require 'spec_helper'
require 'jadeite'

describe "Jadeite" do
  let(:template_str) {
    <<-jade.strip
    p Hello \#{who}
      - if (awesome)
        em Pretty awesome
      p=a.nested.title
      p.
        plain text can have a
        body inside an element
    jade
  }
  let(:template_data) {
    {:who => "world", :awesome => true, :a => {:nested => {:title => "This is the nested title"}}}
  }

  let(:env) {
    Jadeite::Environment.new
  }
  let(:fixtures_path) {"./spec/fixtures"}

  it "renders a jade template with data" do
    env.render(template_str, template_data).should eql "<p>Hello world<em>Pretty awesome</em><p>This is the nested title</p><p>plain text can have a\nbody inside an element</p></p>"
  end

  it "can reference a compiled template and render it several times with various data" do

    compiled = env.compile(template_str, template_data)

    compiled.render(template_data).should eql "<p>Hello world<em>Pretty awesome</em><p>This is the nested title</p><p>plain text can have a\nbody inside an element</p></p>"

    other_data = {:who => "moon!", :awesome => false, :a => {:nested => {:title => "Have you seen my dark side?"}}}
    compiled.render(other_data).should eql "<p>Hello moon!<p>Have you seen my dark side?</p><p>plain text can have a\nbody inside an element</p></p>"

  end

  it "Will fail if reference data is missing" do

    compiled = env.compile(template_str, template_data)

    other_data = {:who => "moon!", :awesome => false, :a => {}}
    ->{ compiled.render(other_data) }.should raise_error(V8::JSError, "Cannot read property 'title' of undefined")
  end

  it "Can handle a more complex example" do

    compiled = env.compile(File.read("#{fixtures_path}/form.jade"))
    
    compiled.render(:user => {:name => "Bengel"}).should eq "<form method=\"post\"><fieldset><legend>General</legend><p><label for=\"user[name]\">Username:<input type=\"text\" name=\"user[name]\" value=\"Bengel\"/></label></p><p><label for=\"user[email]\">Email:<input type=\"text\" name=\"user[email]\"/><div class=\"tip\">Enter a valid \nemail address \nsuch as <em>tj@vision-media.ca</em>.</div></label></p></fieldset><fieldset><legend>Location</legend><p><label for=\"user[city]\">City:<input type=\"text\" name=\"user[city]\"/></label></p><p><select name=\"user[province]\"><option value=\"\">-- Select Province --</option><option value=\"AB\">Alberta</option><option value=\"BC\">British Columbia</option><option value=\"SK\">Saskatchewan</option><option value=\"MB\">Manitoba</option><option value=\"ON\">Ontario</option><option value=\"QC\">Quebec</option></select></p></fieldset><p class=\"buttons\"><input type=\"submit\" value=\"Save\"/></p></form>"

  end

  it "Handles includes" do
    
    compiled = env.compile_file("#{fixtures_path}/includes.jade")

    compiled.render.should eq "<p>bar</p><body><p>:)</p><script>\n  console.log(\"foo\\nbar\")\n</script></body>"

  end

  it "Handles includes and mixins" do
    
    compiled = env.compile_file("#{fixtures_path}/include-mixin.jade")

    compiled.render.should eq "<html><head><title>My Application</title></head><body><h1>The meaning of life</h1><p>Foo bar baz!</p></body></html>"

  end

  it "Can render a file" do
    env.render_file("#{fixtures_path}/include-mixin.jade").should eq "<html><head><title>My Application</title></head><body><h1>The meaning of life</h1><p>Foo bar baz!</p></body></html>"
  end

  it "Returns a string of the compiled template" do
    env.compile("p", :client => true, :compileDebug => false).to_s.should eq "function anonymous(locals, attrs, escape, rethrow, merge) {\nattrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;\nvar buf = [];\nwith (locals || {}) {\nvar interp;\nbuf.push('<p></p>');\n}\nreturn buf.join(\"\");\n}"
  end
end
