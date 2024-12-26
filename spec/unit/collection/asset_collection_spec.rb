# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Collections::AssetCollection do
  subject { described_class.new(assets) }

  let(:assets) do
    [
      Glossarist::Asset.new({ path: "some/random/path" }),
      Glossarist::Asset.new({ path: "some/random/path/2" }),
      Glossarist::Asset.new({ path: "another/random/path" }),
    ]
  end

  it "should have 3 items" do
    expect(subject.size).to eq(3)
  end

  context "adding duplicate asset" do
    it { expect { subject << assets[0] }.not_to change { subject.count } }
  end

  context "adding unique asset" do
    let(:asset) { Glossarist::Asset.new({ path: "some/random/path/3" }) }

    it { expect { subject << asset }.to change { subject.count }.from(3).to(4) }
  end
end
