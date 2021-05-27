# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Collection do
  let(:collection_index) { subject.instance_variable_get "@index" }

  let(:concept1234) { double("concept 1234", id: "1234") }
  let(:concept3456) { double("concept 3456", id: "3456") }

  it "includes Enumerable module" do
    expect(subject).to be_kind_of(Enumerable)
    expect(subject).to respond_to(:to_a) & respond_to(:map) & respond_to(:grep)
  end

  describe "#fetch" do
    before { collection_index["1234"] = concept1234 }

    it "returns concept of given ID if it's present in the collection" do
      expect(subject.fetch("1234")).to be(concept1234)
    end

    it "returns nil when there is no concept of given ID in the collection" do
      expect(subject.fetch("7890")).to be(nil)
    end

    it "is aliased as #[]" do
      expect(subject.method(:[])).to eq(subject.method(:fetch))
    end
  end

  describe "#store" do
    it "adds concept to the collection if it wasn't there before" do
      expect { subject.store(concept1234) }
        .to change { collection_index.size }.by(1)
        .and change { collection_index["1234"] }.to(concept1234)
    end

    it "replaces concept of the same ID if one is already in the collection" do
      collection_index["1234"] = double("old 1234")

      expect { subject.store(concept1234) }
        .to preserve { collection_index.size }
        .and change { collection_index["1234"] }.to(concept1234)
    end

    it "is aliased as #<<" do
      expect(subject.method(:<<)).to eq(subject.method(:store))
    end
  end

  describe "#each" do
    before { collection_index["1234"] = concept1234 }
    before { collection_index["3456"] = concept3456 }

    it "iterates through concepts when called with a block" do
      yielded = []
      subject.each { |concept| yielded << concept }
      expect(yielded).to contain_exactly(concept1234, concept3456)
    end

    it "returns an Enumerator when called without a block" do
      expect(subject.each).to be_kind_of(Enumerator)
    end
  end
end
