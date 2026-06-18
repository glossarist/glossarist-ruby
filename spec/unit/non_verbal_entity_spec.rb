# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::NonVerbalEntity do
  describe "shared payload" do
    it "declares caption, description, alt, sources only" do
      expected = %i[caption description alt sources].to_set
      expect(described_class.attributes.keys.to_set).to include(expected)
    end

    it "does not declare id or identifier" do
      keys = described_class.attributes.keys
      expect(keys).not_to include(:id)
      expect(keys).not_to include(:identifier)
    end
  end

  describe "#find_by_id" do
    it "returns nil on the base" do
      entity = described_class.new(caption: { "eng" => "x" })
      expect(entity.find_by_id("anything")).to be_nil
    end
  end

  describe "#all_ids" do
    it "returns an empty array on the base" do
      expect(described_class.new.all_ids).to eq([])
    end
  end
end

RSpec.describe Glossarist::SharedNonVerbalEntity do
  it "inherits from NonVerbalEntity" do
    expect(described_class).to be < Glossarist::NonVerbalEntity
  end

  it "adds id and identifier" do
    keys = described_class.attributes.keys
    expect(keys).to include(:id, :identifier)
  end

  describe "#find_by_id" do
    it "matches by id" do
      entity = described_class.new(id: "fig_A.1")
      expect(entity.find_by_id("fig_A.1")).to be entity
    end

    it "returns nil when id does not match" do
      entity = described_class.new(id: "fig_A.1")
      expect(entity.find_by_id("fig_A.2")).to be_nil
    end
  end

  describe "#all_ids" do
    it "returns [id]" do
      entity = described_class.new(id: "fig_A.1")
      expect(entity.all_ids).to eq(["fig_A.1"])
    end

    it "omits nil ids" do
      expect(described_class.new.all_ids).to eq([])
    end
  end
end

RSpec.describe "dataset-shared entity hierarchy" do
  it "Figure is a SharedNonVerbalEntity" do
    expect(Glossarist::Figure).to be < Glossarist::SharedNonVerbalEntity
  end

  it "Table is a SharedNonVerbalEntity" do
    expect(Glossarist::Table).to be < Glossarist::SharedNonVerbalEntity
  end

  it "Formula is a SharedNonVerbalEntity" do
    expect(Glossarist::Formula).to be < Glossarist::SharedNonVerbalEntity
  end
end
