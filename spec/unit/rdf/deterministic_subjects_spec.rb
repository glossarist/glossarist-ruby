# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "rdf/turtle"
require "glossarist/transforms/concept_to_gloss_transform"

RSpec.describe "Deterministic subject IDs (B2)" do
  let(:fixtures_dir) { fixtures_path("concept_collection_v2") }

  def load_concept
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_dir)
    collection.first
  end

  def emit_turtle
    transform = Glossarist::Transforms::ConceptToGlossTransform.new(load_concept)
    transform.to_turtle
  end

  it "produces stable definition IDs across separate processes" do
    skip "requires fork" unless Process.respond_to?(:fork)

    read, write = IO.pipe
    pid = Process.fork do
      read.close
      write.write(emit_turtle)
      write.close
      exit!
    end
    write.close
    output1 = read.read
    read.close
    Process.wait(pid)

    output2 = emit_turtle

    ids1 = output1.scan(%r{definition/([0-9a-f]+)}).flatten.uniq
    ids2 = output2.scan(%r{definition/([0-9a-f]+)}).flatten.uniq
    expect(ids1).to eq(ids2)
  end

  it "uses Digest::MD5 for definition subjects (12 hex chars)" do
    ttl = emit_turtle
    expect(ttl).to match(%r{definition/[0-9a-f]{12}})
  end
end
