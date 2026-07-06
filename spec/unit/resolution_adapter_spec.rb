# frozen_string_literal: true

require "spec_helper"
require "net/http"

RSpec.describe Glossarist::ResolutionAdapter::Remote do
  let(:adapter) do
    described_class.new(uri_prefix: "urn:iec:std:iec:60050",
                        endpoint: "https://example.org/api")
  end

  # Lightweight HTTP response stub. Implements the subset of Net::HTTPResponse
  # the adapter actually uses: is_a?(Net::HTTPSuccess) via kind_of?, the
  # content-type header via [], and #body. Replaces double("response", ...)
  # per the global "no doubles" rule.
  class FakeHttpResponse
    def initialize(success:, content_type: "application/json", body: "")
      @success = success
      @content_type = content_type
      @body = body
    end

    def is_a?(klass)
      klass == Net::HTTPSuccess ? @success : super
    end
    alias kind_of? is_a?

    def [](_header)
      @content_type
    end

    attr_reader :body
  end

  describe "#resolve" do
    it "returns nil for non-urn ref_type" do
      ref = Glossarist::ConceptReference.new(term: "test", concept_id: "1",
                                             ref_type: "local")
      expect(adapter.resolve(ref)).to be_nil
    end

    it "returns nil for unmatched uri_prefix" do
      ref = Glossarist::ConceptReference.new(term: "test", concept_id: "1",
                                             source: "urn:iso:std:iso:19111",
                                             ref_type: "urn")
      expect(adapter.resolve(ref)).to be_nil
    end

    it "returns parsed JSON for matching reference" do
      ref = Glossarist::ConceptReference.new(term: "equality",
                                             concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050",
                                             ref_type: "urn")

      response = FakeHttpResponse.new(success: true,
                                      body: '{"termid":"102-01-01"}')
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      result = adapter.resolve(ref)
      expect(result).to eq({ "termid" => "102-01-01" })
    end

    it "caches results across calls" do
      ref = Glossarist::ConceptReference.new(term: "equality",
                                             concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050",
                                             ref_type: "urn")

      response = FakeHttpResponse.new(success: true,
                                      body: '{"termid":"102-01-01"}')
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      adapter.resolve(ref)
      adapter.resolve(ref)
      expect(Net::HTTP).to have_received(:get_response).once
    end

    it "returns nil on network error" do
      ref = Glossarist::ConceptReference.new(term: "equality",
                                             concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050",
                                             ref_type: "urn")
      allow(Net::HTTP).to receive(:get_response).and_raise(SocketError)

      expect(adapter.resolve(ref)).to be_nil
    end

    it "returns nil on non-success HTTP response" do
      ref = Glossarist::ConceptReference.new(term: "equality",
                                             concept_id: "102-01-01",
                                             source: "urn:iec:std:iec:60050",
                                             ref_type: "urn")

      response = FakeHttpResponse.new(success: false)
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      expect(adapter.resolve(ref)).to be_nil
    end
  end
end
