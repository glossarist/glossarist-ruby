# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::Registry do
  before do
    @saved = described_class.rule_classes
    described_class.reset!
  end

  after do
    described_class.reset!
    @saved.each { |r| described_class.register(r) }
  end

  let(:dummy_rule) do
    Class.new(Glossarist::Validation::Rules::Base) do
      def code = "TEST-001"
      def category = :structure
      def scope = :concept
    end
  end

  let(:collection_rule) do
    Class.new(Glossarist::Validation::Rules::Base) do
      def code = "TEST-002"
      def category = :integrity
      def scope = :collection
    end
  end

  describe ".register" do
    it "adds a rule class to the registry" do
      described_class.register(dummy_rule)
      expect(described_class.all).to include(a_kind_of(dummy_rule))
    end

    it "does not duplicate registrations" do
      described_class.register(dummy_rule)
      described_class.register(dummy_rule)
      expect(described_class.rule_classes.count(dummy_rule)).to eq(1)
    end
  end

  describe ".all" do
    it "returns instances of all registered rule classes" do
      described_class.register(dummy_rule)
      described_class.register(collection_rule)
      instances = described_class.all
      expect(instances.size).to eq(2)
      expect(instances.map(&:class)).to contain_exactly(dummy_rule, collection_rule)
    end

    it "returns empty array when nothing registered" do
      expect(described_class.all).to eq([])
    end
  end

  describe ".for_category" do
    it "returns rules matching the given category" do
      described_class.register(dummy_rule)
      described_class.register(collection_rule)
      expect(described_class.for_category(:structure).map(&:class)).to eq([dummy_rule])
    end

    it "returns empty when no rules match" do
      described_class.register(dummy_rule)
      expect(described_class.for_category(:localization)).to eq([])
    end
  end

  describe ".for_scope" do
    it "returns rules matching the given scope" do
      described_class.register(dummy_rule)
      described_class.register(collection_rule)
      expect(described_class.for_scope(:concept).map(&:class)).to eq([dummy_rule])
      expect(described_class.for_scope(:collection).map(&:class)).to eq([collection_rule])
    end
  end

  describe ".find" do
    it "returns the rule instance matching the code" do
      described_class.register(dummy_rule)
      found = described_class.find("TEST-001")
      expect(found).to be_a(dummy_rule)
    end

    it "returns nil when no rule matches" do
      expect(described_class.find("NONEXISTENT")).to be_nil
    end
  end

  describe ".reset!" do
    it "removes all registered rules" do
      described_class.register(dummy_rule)
      described_class.reset!
      expect(described_class.all).to eq([])
    end
  end
end
