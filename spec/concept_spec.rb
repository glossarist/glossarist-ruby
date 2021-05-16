# frozen_string_literal: true

RSpec.describe Glossarist::Concept do
  subject { described_class.new attrs }

  let(:attrs) { { id: "123" } }

  it "accepts strings as ids" do
    expect { subject.id = "456" }
      .to change { subject.id }.to("456")
  end

  describe "#localizations" do
    let(:eng) { Glossarist::LocalizedConcept.new }

    it "is an array of localized concepts" do
      expect { subject.localizations.merge! "eng" => eng }
        .to change { subject.localizations }.to({ "eng" => eng })
    end
  end
end