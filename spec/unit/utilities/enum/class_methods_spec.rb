# frozen_string_literal: true

RSpec.describe Glossarist::Utilities::Enum::ClassMethods do
  let!(:subject) do
    class TmpClass
      extend Glossarist::Utilities::Enum::ClassMethods
    end
  end

  describe ".register_enum" do
    it "register enums for the class" do
      subject.register_enum(:status, [:active, :inactive])
      expect(subject.registered_enums).to eq([:status])

      subject.register_enum(:number, [:singular, :dual, :plural], multiple: true)
      expect(subject.registered_enums).to eq([:status, :number])
    end
  end

  describe ".enums" do
    it "returns all registered enums" do
      expected_enums = {
        status: {
          registered_values: %i[active inactive],
          options: {}
        },
        number: {
          registered_values: %i[singular dual plural],
          options: { multiple: true }
        }
      }

      expect(subject.enums).to eq(expected_enums)
    end
  end

  describe ".registered_enums" do
    it "returns names of all registered enums" do
      expect(subject.registered_enums).to eq(%i[status number])
    end
  end

  describe ".valid_types" do
    it "return valid types for `status` enum" do
      expect(subject.valid_types(:status)).to eq(%i[active inactive])
    end

    it "return valid types for `number` enum" do
      expect(subject.valid_types(:number)).to eq(%i[singular dual plural])
    end
  end

  describe ".type_options" do
    it "return options for `status` enum" do
      expect(subject.type_options(:status)).to eq({})
    end

    it "return options for `number` enum" do
      expect(subject.type_options(:number)).to eq({ multiple: true })
    end
  end

  describe ".register_type_reader" do
    it "adds a <type> method to class" do
      expect(subject.method_defined?(:foo)).to be(false)

      subject.register_type_reader(:foo)
      expect(subject.method_defined?(:foo)).to be(true)
    end
  end

  describe ".register_type_writer" do
    it "adds a <type=> method to class" do
      expect(subject.method_defined?(:foo=)).to be(false)

      subject.register_type_reader(:foo=)
      expect(subject.method_defined?(:foo=)).to be(true)
    end
  end

  describe ".register_type_accessor" do
    it "adds a <type> and <type=> method to class" do
      expect(subject.method_defined?(:bar)).to be(false)
      expect(subject.method_defined?(:bar=)).to be(false)

      subject.register_type_accessor(:bar)
      expect(subject.method_defined?(:bar)).to be(true)
      expect(subject.method_defined?(:bar=)).to be(true)
    end
  end

  describe ".add_check_method" do
    it "adds a <type?> method to class" do
      expect(subject.method_defined?(:male?)).to be(false)

      subject.add_check_method(:foo, :male)
      expect(subject.method_defined?(:male?)).to be(true)
    end
  end

  describe ".add_set_method" do
    it "adds a <type=> method to class" do
      expect(subject.method_defined?(:baz=)).to be(false)

      subject.add_set_method(:baz, :alpha)
      expect(subject.method_defined?(:alpha=)).to be(true)
    end
  end
end
