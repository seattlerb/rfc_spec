##
# RfcSpec - speccing the rfc way
#
# Based on RFC 2119: "Key words for use in RFCs to Indicate Requirement Levels"
#
# Abstract:
#
#    In many standards track documents several words are used to
#    signify the requirements in the specification. These words are
#    often capitalized. This document defines these words as they
#    should be interpreted in IETF documents. Authors who follow these
#    guidelines should incorporate this phrase near the beginning of
#    their document:
#
#       The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
#       NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and
#       "OPTIONAL" in this document are to be interpreted as described
#       in RFC 2119.
#
#    Note that the force of these words is modified by the requirement
#    level of the document in which they are used.
#
# 1. MUST -- This word, or the terms "REQUIRED" or "SHALL", mean that
#    the definition is an absolute requirement of the specification.
#
# 2. MUST NOT -- This phrase, or the phrase "SHALL NOT", mean that the
#    definition is an absolute prohibition of the specification.
#
# 3. SHOULD -- This word, or the adjective "RECOMMENDED", mean that
#    there may exist valid reasons in particular circumstances to
#    ignore a particular item, but the full implications must be
#    understood and carefully weighed before choosing a different
#    course.
#
# 4. SHOULD NOT -- This phrase, or the phrase "NOT RECOMMENDED" mean
#    that there may exist valid reasons in particular circumstances
#    when the particular behavior is acceptable or even useful, but
#    the full implications should be understood and the case carefully
#    weighed before implementing any behavior described with this
#    label.
#
# 5. MAY -- This word, or the adjective "OPTIONAL", mean that an item
#    is truly optional. One vendor may choose to include the item
#    because a particular marketplace requires it or because the
#    vendor feels that it enhances the product while another vendor
#    may omit the same item. An implementation which does not include
#    a particular option MUST be prepared to interoperate with another
#    implementation which does include the option, though perhaps with
#    reduced functionality. In the same vein an implementation which
#    does include a particular option MUST be prepared to interoperate
#    with another implementation which does not include the option
#    (except, of course, for the feature the option provides.)
#
# 6. Guidance in the use of these Imperatives
#
#    Imperatives of the type defined in this memo must be used with
#    care and sparingly. In particular, they MUST only be used where
#    it is actually required for interoperation or to limit behavior
#    which has potential for causing harm (e.g., limiting
#    retransmisssions) For example, they must not be used to try to
#    impose a particular method on implementors where the method is
#    not required for interoperability.
#
# 7. Security Considerations
#
#    These terms are frequently used to specify behavior with security
#    implications.  The effects on security of not implementing a MUST or
#    SHOULD, or doing something the specification says MUST NOT or SHOULD
#    NOT be done may be very subtle. Document authors should take the time
#    to elaborate the security implications of not following
#    recommendations or requirements as most implementors will not have
#    had the benefit of the experience and discussion that produced the
#    specification.

class RFCSpec < MiniTest::Unit::TestCase
  VERSION = '1.0.0'

  def self.before &block
    define_method :before, &block
  end

  def self.after &block
    define_method :after, &block
  end

  def self.it name, &block
    block ||= proc { skip "(no tests defined)" }

    define_method "test_#{name.gsub(/\W/, '_')}", &block
  end

  def before; end # do nothing
  def after; end  # do nothing

  class Failure < RuntimeError; end

  module Verifications
    $levels = {
      "must"       => ["is_required_to", "shall"],
      "must_not"   => ["shall_not"],
      "should"     => ["is_recommended_to"],
      "should_not" => ["is_not_recommended_to"],
      "may"        => ["optionally"],
    }

    $verbs = { # and whether they have a negative analog
      "be"                => true,
      "be_close_to"       => true,
      "be_empty"          => true,
      "be_instance_of"    => true,
      "be_kind_of"        => true,
      "be_nil"            => true,
      "be_the_same_as"    => true,
      "be_silent"         => false,
      "be_within_delta"   => true,
      "be_within_epsilon" => true,
      "equal"             => true,
      "include"           => true,
      "match"             => true,
      "output"            => false,
      "raise"             => false,
      "respond_to"        => true,
      "send"              => false,
      "throw"             => false,
    }

    LEVEL_RE = Regexp.union($levels.to_a.flatten.sort_by { |s| -s.size })
    VERB_RE  = Regexp.union($verbs.keys.sort_by { |s| -s.size })

    # def __whereami?
    #   caller.first =~ /\`(#{LEVEL_RE})_(#{VERB_RE})\'/ and [$1, $2]
    # end

    def __level
      caller.first =~ /\`(#{LEVEL_RE})_(#{VERB_RE})\'/ and $1
    end

    def __verify test, message = "failed"
      where = caller.first[/\`(\w+)\'/, 1]
      positive = where !~ /_not_/
      test = ! test unless positive

      result =
      case where
      when /^(must|shall|is_required_to)_/ then
        test or raise Failure, message
      when /^(should_|is_(not_)?recommended_to|optionally|may)/ then
        test # TODO: record failed should
        true # HACK :maybe?
      else
        raise "unsupported : #{where.inspect}"
      end

      result = ! result unless positive
      result
    end

    def capture_io
      require 'stringio'
      orig_stdout, orig_stderr         = $stdout, $stderr
      captured_stdout, captured_stderr = StringIO.new, StringIO.new
      $stdout, $stderr                 = captured_stdout, captured_stderr
      yield
      return captured_stdout.string, captured_stderr.string
    ensure
      $stdout = orig_stdout
      $stderr = orig_stderr
    end

    def must_be op, *args
      __verify self.send(op, *args)
    end

    def must_be_close_to exp, delta = 0.001
      __verify delta >= (exp - self).abs
    end

    def must_be_instance_of klass
      __verify self.instance_of? klass
    end

    def must_be_kind_of klass
      __verify self.kind_of? klass
    end

    def must_be_nil
      __verify self.nil?
    end

    def must_be_the_same_as other
      __verify self.equal? other
    end

    def must_be_silent
      self.send "#{__level}_output", "", ""
    end

    def must_equal other
      __verify self == other, "#{self.inspect} != #{other.inspect}"
    end

    def must_include other
      __verify self.include? other
    end

    def must_match re
      __verify !!(self =~ re)
    end

    def must_output stdout = nil, stderr = nil
      out, err = capture_io do
        self.call
      end
      x = out.send "#{__level}_equal", stdout if stdout
      y = err.send "#{__level}_equal", stderr if stderr
      (!stdout || x) && (!stderr || y)
    end

    def must_raise klass
      e = nil
      begin
        self.call
      rescue => e
        # yay
      end
      e.class.send("#{__level}_equal", klass)
    end

    def must_respond_to msg
      __verify self.respond_to?(msg)
    end

    def must_throw sym
      caught = true
      catch(sym) do
        begin
          self.call
        rescue ArgumentError => e     # 1.9 exception
        rescue NameError => e         # 1.8 exception
        end
        caught = false
      end
      __verify caught
    end

    methods = self.public_instance_methods(false).sort

    $levels.to_a.flatten.each do |level|
      next if level == "must"

      $verbs.each do |verb, negative|
        new_method = "#{level}_#{verb}"
        old_method = "must_#{verb}"
        next if !negative && level =~ /_not/
        next unless methods.include? old_method
        next if methods.include? new_method
        alias_method new_method, old_method
      end
    end
  end
end

# HACK this is for my own sanity only
Object.public_instance_methods.grep(/must|wont/).each do |m|
  Object.send :remove_method, m
end

Object.send :include, RFCSpec::Verifications

module Kernel
  ##
  # Describe a series of expectations for a given target +desc+.

  def rfc_describe thingy = nil, &block
    cls = Class.new RFCSpec
    cls.instance_eval(&block) if block_given?
    cls
  end

  private :rfc_describe
end
