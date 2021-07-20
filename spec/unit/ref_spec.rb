# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Ref do
  subject { described_class.new attrs }

  let(:attrs) { { text: "some ref" } }

  it "accepts strings as text" do
    expect { subject.text = "new one" }
      .to change { subject.text }.to("new one")
  end

  it "accepts strings as source" do
    expect { subject.source = "new one" }
      .to change { subject.source }.to("new one")
  end

  it "accepts strings as id" do
    expect { subject.id = "new one" }
      .to change { subject.id }.to("new one")
  end

  it "accepts strings as version" do
    expect { subject.version = "new one" }
      .to change { subject.version }.to("new one")
  end

  it "accepts strings as clause" do
    expect { subject.clause = "new one" }
      .to change { subject.clause }.to("new one")
  end

  it "accepts strings as link" do
    expect { subject.link = "new one" }
      .to change { subject.link }.to("new one")
  end

  it "accepts strings as status" do
    expect { subject.status = "new one" }
      .to change { subject.status }.to("new one")
  end

  it "accepts strings as modification" do
    expect { subject.modification = "new one" }
      .to change { subject.modification }.to("new one")
  end

  it "accepts strings as original" do
    expect { subject.original = "new one" }
      .to change { subject.original }.to("new one")
  end
end
