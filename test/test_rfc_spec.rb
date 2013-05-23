require "rubygems"
require "minitest/autorun"
require "rfc_spec"

include RFCSpec::Verifications

spec = nil # for test reflection at end of file

rfc_describe RFCSpec do

  ############################################################
  # Structural:

  rfc_describe :describe do
    it "should create a class" do
      x = rfc_describe "top-level thingy"
      x.must_be_kind_of Class
      x.ancestors.must_include RFCSpec
    end

    it "should be nestable" do
      x = y = nil
      x = rfc_describe "top-level thingy" do
        before {}
        after  {}

        it "top-level-it" do end

        y = rfc_describe "inner thingy" do
          before {}
          it "inner-it" do end
        end
      end

      top_methods   = %w(after before test_top_level_it)
      inner_methods = %w(      before test_inner_it)

      top_methods.must_equal   x.instance_methods(false).sort.map(&:to_s)
      inner_methods.must_equal y.instance_methods(false).sort.map(&:to_s)
    end
  end

  spec = rfc_describe RFCSpec::Verifications do
    ############################################################
    # 1. MUST

    %w(must is_required_to shall).each do |level|
      it "implements #{level}_be" do
        41.send("#{level}_be", :<, 42).must_equal true
        proc { 42.send("#{level}_be", :<, 41) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_close_to" do
        42.000.send("#{level}_be_close_to", 42.0).must_equal true
        proc { 42.002.send("#{level}_be_close_to", 42.0) }.
          must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_instance_of" do
        42.send("#{level}_be_instance_of", Fixnum).must_equal true
        proc { 42.send("#{level}_be_instance_of", String) }.
          must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_kind_of" do
        42.send("#{level}_be_kind_of", Fixnum).must_equal true
        42.send("#{level}_be_kind_of", Numeric).must_equal true
        proc { 42.send("#{level}_be_kind_of", Array) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_nil" do
        nil.must_be_nil.must_equal true
        proc { 42.must_be_nil }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_silent" do
        proc {  }.must_be_silent.must_equal true
        proc { proc { print "xxx" }.must_be_silent }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_the_same_as" do
        1.send("#{level}_be_the_same_as", 1).must_equal true
        proc { 1.must_be_the_same_as 2 }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_equal" do
        42.send("#{level}_equal", 42).must_equal true
        proc { 24.send("#{level}_equal", 42) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_include" do
        [1, 2, 3].send("#{level}_include", 2).must_equal true
        proc { [1, 2, 3].send("#{level}_include", 4) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_match" do
        "blah".send("#{level}_match", /\w+/).must_equal true
        proc { "blah".send("#{level}_match", /\d+/) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_output" do
        proc { print "blah" }.send("#{level}_output", "blah").must_equal true
        proc { $stderr.print "blah" }.send("#{level}_output", nil, "blah").
          must_equal true
        proc {
          proc { print "xxx" }.send("#{level}_output", "blah")
        }.must_raise RFCSpec::Failure
        proc {
          proc { $stderr.print "xxx" }.send("#{level}_output", nil, "blah")
        }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_raise" do
        proc { raise "blah" }.send("#{level}_raise", RuntimeError).must_equal true
        proc { proc { }.send("#{level}_raise", RuntimeError) }.
          must_raise(RFCSpec::Failure)
        proc { proc { raise "blah" }.send("#{level}_raise", ArgumentError) }.
          must_raise(RFCSpec::Failure).must_equal true
        proc { raise RFCSpec::Failure }.
          send("#{level}_raise", RFCSpec::Failure).must_equal true
        proc { proc { 42 }.send("#{level}_raise", RuntimeError) }.
          must_raise(RFCSpec::Failure).must_equal true
      end

      it "implements #{level}_respond_to" do
        42.send("#{level}_respond_to", :+).must_equal true
        proc { 42.send("#{level}_respond_to", :clear) }.
          must_raise RFCSpec::Failure
      end

      it "implements #{level}_throw" do
        proc { throw :blah }.send("#{level}_throw", :blah).must_equal true
        proc { proc {            }.send("#{level}_throw", :blah) }.
          must_raise RFCSpec::Failure
        proc { proc { throw :xxx }.send("#{level}_throw", :blah) }.
          must_raise RFCSpec::Failure
      end
    end

    ############################################################
    # 2. MUST NOT

    %w(must_not shall_not).each do |level|
      it "implements #{level}_be" do
        41.send("#{level}_be", :>, 42).must_equal false
        proc { 42.send("#{level}_be", :>, 41) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_close_to" do
        42.000.send("#{level}_be_close_to", 42.002).must_equal false
        proc { 42.00.send("#{level}_be_close_to", 42.0) }.
          must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_instance_of" do
        42.send("#{level}_be_instance_of", String).must_equal false
        proc { 42.send("#{level}_be_instance_of", Fixnum) }.
          must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_kind_of" do
        42.send("#{level}_be_kind_of", Array).must_equal false
        proc { 42.send("#{level}_be_kind_of", Fixnum) }.
          must_raise RFCSpec::Failure
        proc { 42.send("#{level}_be_kind_of", Numeric) }.
          must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_nil" do
        42.send("#{level}_be_nil").must_equal false
        proc { nil.send("#{level}_be_nil") }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_be_the_same_as" do
        1.send("#{level}_be_the_same_as", 2).must_equal false
        proc { 1.send("#{level}_be_the_same_as", 1) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_equal" do
        42.send("#{level}_equal", 41).must_equal false
        proc { 1.send("#{level}_equal", 1) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_include" do
        [1, 2, 3].send("#{level}_include", 4).must_equal false
        proc { [1, 2, 3].send("#{level}_include", 2) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_match" do
        "blah".send("#{level}_match", /\d+/).must_equal false
        proc { "blah".send("#{level}_match", /\w+/) }.must_raise RFCSpec::Failure
      end

      it "implements #{level}_respond_to" do
        42.send("#{level}_respond_to", :clear).must_equal false
        proc { 42.send("#{level}_respond_to", :+) }.
          must_raise RFCSpec::Failure
      end
    end

    ############################################################
    # 3. SHOULD
    ############################################################
    # 4. SHOULD NOT
    ############################################################
    # 5. MAY

    levels = %w(should should_not may is_not_recommended_to is_recommended_to
                optionally)
    levels.each do |level|
      val = !(level =~ /not/)

      it "implements #{level}_be" do
        41.send("#{level}_be", :<, 42).must_equal val
        42.send("#{level}_be", :<, 41).must_equal val
      end

      it "implements #{level}_be_close_to" do
        42.000.send("#{level}_be_close_to", 42.0).must_equal val
        42.002.send("#{level}_be_close_to", 42.0).must_equal val
      end

      it "implements #{level}_be_instance_of" do
        42.send("#{level}_be_instance_of", Fixnum).must_equal val
        42.send("#{level}_be_instance_of", String).must_equal val
      end

      it "implements #{level}_be_kind_of" do
        42.send("#{level}_be_kind_of", Fixnum).must_equal val
        42.send("#{level}_be_kind_of", Numeric).must_equal val
        42.send("#{level}_be_kind_of", Array).must_equal val
      end

      it "implements #{level}_be_nil" do
        nil.send("#{level}_be_nil").must_equal val
        42.send("#{level}_be_nil").must_equal val
      end

      it "implements #{level}_be_silent" do
        proc {  }.send("#{level}_be_silent").must_equal val
        proc { print "xxx" }.send("#{level}_be_silent").must_equal val
      end unless level =~ /not/

      it "implements #{level}_be_the_same_as" do
        1.send("#{level}_be_the_same_as", 1).must_equal val
        1.send("#{level}_be_the_same_as", 2).must_equal val
      end

      it "implements #{level}_equal" do
        42.send("#{level}_equal", 42).should_equal val
        42.send("#{level}_equal", 24).should_equal val
      end

      it "implements #{level}_include" do
        [1, 2, 3].send("#{level}_include", 2).must_equal val
        [1, 2, 3].send("#{level}_include", 4).must_equal val
      end

      it "implements #{level}_match" do
        "blah".send("#{level}_match", /\w+/).must_equal val
        "blah".send("#{level}_match", /\d+/).must_equal val
      end

      it "implements #{level}_output" do
        proc { print "blah" }.send("#{level}_output", "blah").must_equal val
        proc { $stderr.print "blah" }.send("#{level}_output", nil, "blah").
          must_equal val
        proc { print "xxx" }.send("#{level}_output", "blah").must_equal val
        proc { $stderr.print "xxx" }. should_output(nil, "blah").must_equal val
      end unless level =~ /not/

      it "implements #{level}_raise" do
        proc { raise "blah" }.send("#{level}_raise", RuntimeError).must_equal val
        proc { proc { raise "x" }.send("#{level}_raise", ArgumentError) }.call.
          must_equal val
        proc { proc {           }.send("#{level}_raise", RuntimeError) }.call.
          must_equal val
      end unless level =~ /not/

      it "implements #{level}_respond_to" do
        42.send("#{level}_respond_to", :+).must_equal val
        42.send("#{level}_respond_to", :clear).must_equal val
      end

      it "implements #{level}_throw" do
        proc { throw :blah }.send("#{level}_throw", :blah).must_equal val
        proc {             }.send("#{level}_throw", :blah).must_equal val
        proc { throw :xxx  }.send("#{level}_throw", :blah).must_equal val
      end unless level =~ /not/
    end

    ############################################################
    # misc

    it "implements capture_io" do
      out, err = capture_io do
        puts "hi"
        warn "bye!"
      end

      out.must_equal "hi\n"
      err.must_equal "bye!\n"
    end
  end
end

class Array
  def grepmap(re, *a)
    self.grep(re).map { |s| s[re, *a] }
  end
end

tests = spec.public_instance_methods(false).grepmap(/^test_implements_(\w+)/, 1)
impls = RFCSpec::Verifications.public_instance_methods(false).sort.map(&:to_s)

untested = impls.select { |s| s !~ /^__/ } - tests

untested.sort.each do |name|
  warn "  it 'implements #{name}' do\n    skip 'not done yet'\n  end\n"
end
