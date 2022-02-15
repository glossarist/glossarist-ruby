# frozen_string_literal: true

RSpec.describe Glossarist::Utilities::Enum do
  shared_examples "test inluded and extended classes" do
    it "should include InstanceMethods" do
      instance_methods_included = test_class.include?(described_class::InstanceMethods)

      expect(instance_methods_included).to be(true)
    end

    it "should extend ClassMethods" do
      class_methods_extended = test_class.singleton_class.include?(described_class::ClassMethods)

      expect(class_methods_extended).to be(true)
    end

    it "should not include ClassMethods" do
      class_methods_included = test_class.include?(described_class::ClassMethods)

      expect(class_methods_included).to be(false)
    end

    it "should not extend InstanceMethods" do
      instance_methods_extended = test_class.singleton_class.include?(described_class::InstanceMethods)

      expect(instance_methods_extended).to be(false)
    end
  end

  context "when included" do
    let!(:test_class) do
      class TempIncludeClass
        include Glossarist::Utilities::Enum
      end
    end

    include_examples "test inluded and extended classes"
  end

  context "when extended" do
    let!(:test_class) do
      class TempExtendClass
        extend Glossarist::Utilities::Enum
      end
    end

    include_examples "test inluded and extended classes"
  end
end
