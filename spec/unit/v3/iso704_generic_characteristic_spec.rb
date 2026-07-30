# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

# ISO 704:2022 §5.5.4.2.1 Examples 3 + 4 — the canonical multi-criterion
# generic-hyperedge case. Computer mouse (the genus) has TWO
# decompositions:
#
#   1. By means of movement detection:
#      mechanical mouse, optomechanical mouse, optical mouse
#   2. By computer connection:
#      wired mouse, wireless mouse
#
# Each species carries its own delimiting characteristic under the
# hyperedge's criterion of subdivision. This spec verifies the model
# + per-file format + round-trip preserves all of it.

RSpec.describe "ISO 704:2022 §5.5.4.2.1 — generic hyperedge delimiting characteristics" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:relations_dir) { File.join(tmpdir, "relations") }

  # The two hyperedges for "computer mouse" (the genus).
  let(:means_of_movement_detection) do
    Glossarist::V3::GenericHyperedge.new(
      comprehensive: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "computer-mouse"),
      criterion: { "eng" => "means of movement detection" },
      completeness: "complete",
      members: [
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "mechanical-mouse"),
          characteristic: { "eng" => "detecting movement by means of rollers" },
        ),
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "optomechanical-mouse"),
          characteristic: { "eng" => "detecting movement by means of rollers and light sensors" },
        ),
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "optical-mouse"),
          characteristic: { "eng" => "detecting movement by means of light sensors" },
        ),
      ],
    )
  end

  let(:computer_connection) do
    Glossarist::V3::GenericHyperedge.new(
      comprehensive: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "computer-mouse"),
      criterion: { "eng" => "computer connection" },
      completeness: "complete",
      members: [
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "wired-mouse"),
          characteristic: { "eng" => "using a corded electrical connection" },
        ),
        Glossarist::V3::GenericMember.new(
          ref: Glossarist::V3::ConceptRef.new(source: "ISO704", id: "wireless-mouse"),
          characteristic: { "eng" => "using a cordless light or sound connection" },
        ),
      ],
    )
  end

  it "models both hyperedges simultaneously for the same genus" do
    rels = [means_of_movement_detection, computer_connection]

    # HyperedgeIndex confirms the multi-hyperedge-per-comprehensive pattern
    index = Glossarist::V3::HyperedgeIndex.new(rels)
    expect(index.for_comprehensive("ISO704:computer-mouse").length).to eq(2)
  end

  it "serializes each hyperedge to its own per-file YAML" do
    rels = [means_of_movement_detection, computer_connection]
    Glossarist::V3::HyperedgeWriter.write_all(rels, relations_dir)

    means_path = File.join(relations_dir, "iso704-computer-mouse", "means-of-movement-detection.yaml")
    conn_path  = File.join(relations_dir, "iso704-computer-mouse", "computer-connection.yaml")
    expect(File.exist?(means_path)).to be(true)
    expect(File.exist?(conn_path)).to be(true)
  end

  it "round-trips the delimiting characteristics through per-file storage" do
    original = means_of_movement_detection
    path = Glossarist::V3::HyperedgeWriter.write(original, relations_dir)
    loaded = Glossarist::V3::RelationLoader.load_file(path)

    expect(loaded.criterion).to eq("eng" => "means of movement detection")
    expect(loaded.members.map { |m| m.ref.id }).to eq(
      %w[mechanical-mouse optomechanical-mouse optical-mouse],
    )
    # The delimiting characteristic per species is preserved exactly
    expect(loaded.members.map { |m| m.characteristic["eng"] }).to eq([
                                                                       "detecting movement by means of rollers",
                                                                       "detecting movement by means of rollers and light sensors",
                                                                       "detecting movement by means of light sensors",
                                                                     ])
  end

  it "distinguishes the two hyperedges by criterion fingerprint" do
    # The deterministic_id includes the criterion fingerprint, so the
    # two hyperedges for computer-mouse have DIFFERENT subject URIs.
    a = Glossarist::V3::HyperedgeWriter.write(means_of_movement_detection, relations_dir)
    b = Glossarist::V3::HyperedgeWriter.write(computer_connection, relations_dir)
    # Different files — same comp dir, different criterion slug
    expect(File.dirname(a)).to eq(File.dirname(b))
    expect(a).not_to eq(b)
  end

  it "reflects multidimensionality (ISO 704 §5.6.3) in the index" do
    rels = [means_of_movement_detection, computer_connection]
    index = Glossarist::V3::HyperedgeIndex.new(rels)

    # mechanical-mouse appears in exactly one hyperedge (means of
    # movement detection), NOT in computer-connection. Coordinate
    # concept sets are distinct.
    mech_hyperedges = index.for_member("ISO704:mechanical-mouse")
    expect(mech_hyperedges.length).to eq(1)
    expect(mech_hyperedges.first.criterion["eng"]).to eq("means of movement detection")
  end

  it "emits RDF with gloss:characteristic per generic member" do
    require "rdf/turtle"
    mc = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "computer-mouse"),
    )
    turtle = Glossarist::Transforms::ConceptToGlossTransform
      .new(mc, relations: [means_of_movement_detection]).to_turtle
    expect(turtle).to include("gloss:characteristic")
    expect(turtle).to include("detecting movement by means of rollers")
  end
end
