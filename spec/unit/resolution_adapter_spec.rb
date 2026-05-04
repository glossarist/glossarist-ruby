# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ResolutionAdapter::Remote do
  let(:adapter) do
    described_class.new(uri_prefix: "urn:iec:std:iec:60050",
                        endpoint: "https://example.org/api")
  end

  describe "#resolve" do
    it "returns nil for non-urn ref_type" do
      ref = Glossarist::ConceptReference.new(term: "test", concept_id: "1",
                                             ref_type: "local")
      expect(adapter.resolve(ref)).to be_nil
    end

    it "returns nil for unmatched uri_prefix" do
      ref = Glossarist::ConceptReference.new(term: "test", concept_id: "1",
                                             source: "urn:iso:std:iso:19111", ref_type: "urn")
      expect(adapter.resolve(ref)).to be_nil
    end

    it "returns parsed JSON for matching reference" do
      ref = Glossarist::ConceptReference.new(term: "equality", concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050", ref_type: "urn")

      body = '{"termid":"102-01-01"}'
      response = double("response", is_a?: true, "[]": "application/json",
                                    body: body)
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      result = adapter.resolve(ref)
      expect(result).to eq({ "termid" => "102-01-01" })
    end

    it "caches results across calls" do
      ref = Glossarist::ConceptReference.new(term: "equality", concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050", ref_type: "urn")

      body = '{"termid":"102-01-01"}'
      response = double("response", is_a?: true, "[]": "application/json",
                                    body: body)
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      adapter.resolve(ref)
      adapter.resolve(ref)
      expect(Net::HTTP).to have_received(:get_response).once
    end

    it "returns nil on network error" do
      ref = Glossarist::ConceptReference.new(term: "equality", concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050", ref_type: "urn")
      allow(Net::HTTP).to receive(:get_response).and_raise(SocketError)

      expect(adapter.resolve(ref)).to be_nil
    end

    it "returns nil on non-success HTTP response" do
      ref = Glossarist::ConceptReference.new(term: "equality", concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050", ref_type: "urn")

      response = double("response", is_a?: false)
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      expect(adapter.resolve(ref)).to be_nil
    end
  end
end
