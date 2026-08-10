# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ConceptRef external + ellipsis (TODO.external-ellipsis)" do
  let(:resolved_ref) { Glossarist::V3::ConceptRef.new(source: "VIM", id: "112-02-09") }
  let(:external_ref) { Glossarist::V3::ConceptRef.new(text: "(precision condition of measurement)", external: true) }
  let(:ellipsis_ref) { Glossarist::V3::ConceptRef.new(ellipsis: true) }
  let(:text_only_ref) { Glossarist::V3::ConceptRef.new(text: "quantum field theory") }

  describe "5 valid forms" do
    it "resolved: source + id" do
      expect(resolved_ref.resolved?).to be(true)
      expect(resolved_ref.external?).to be(false)
      expect(resolved_ref.ellipsis?).to be(false)
    end

    it "external: text + external: true" do
      expect(external_ref.external?).to be(true)
      expect(external_ref.resolved?).to be(false)
      expect(external_ref.text_only?).to be(false)
    end

    it "ellipsis: ellipsis: true only" do
      expect(ellipsis_ref.ellipsis?).to be(true)
      expect(ellipsis_ref.resolved?).to be(false)
      expect(ellipsis_ref.external?).to be(false)
    end

    it "text-only: text without external" do
      expect(text_only_ref.text_only?).to be(true)
      expect(text_only_ref.resolved?).to be(false)
      expect(text_only_ref.external?).to be(false)
    end

    it "empty: all defaults" do
      empty = Glossarist::ConceptRef.new
      expect(empty.resolved?).to be(false)
      expect(empty.external?).to be(false)
      expect(empty.ellipsis?).to be(false)
    end
  end

  describe "validation — mutual exclusivity" do
    it "rejects external: true + source/id" do
      ref = Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.2", external: true)
      expect { ref.validate_ref! }
        .to raise_error(ArgumentError, /external.*must not carry.*source\/id/)
    end

    it "rejects ellipsis: true + source" do
      ref = Glossarist::V3::ConceptRef.new(source: "VIM", ellipsis: true)
      expect { ref.validate_ref! }
        .to raise_error(ArgumentError, /ellipsis.*must not carry/)
    end

    it "rejects ellipsis: true + text" do
      ref = Glossarist::V3::ConceptRef.new(text: "foo", ellipsis: true)
      expect { ref.validate_ref! }
        .to raise_error(ArgumentError, /ellipsis.*must not carry/)
    end

    it "rejects ellipsis: true + external" do
      ref = Glossarist::V3::ConceptRef.new(external: true, ellipsis: true)
      expect { ref.validate_ref! }
        .to raise_error(ArgumentError, /ellipsis.*must not carry/)
    end

    it "rejects completely empty ConceptRef" do
      ref = Glossarist::ConceptRef.new
      expect { ref.validate_ref! }
        .to raise_error(ArgumentError, /must have at least one/)
    end

    it "passes for each valid form" do
      [resolved_ref, external_ref, ellipsis_ref, text_only_ref].each do |ref|
        expect { ref.validate_ref! }.not_to raise_error
      end
    end
  end

  describe "YAML round-trip" do
    it "round-trips external ref" do
      yaml = external_ref.to_yaml
      restored = Glossarist::ConceptRef.from_yaml(yaml)
      expect(restored.external?).to be(true)
      expect(restored.text).to eq("(precision condition of measurement)")
    end

    it "round-trips ellipsis ref" do
      yaml = ellipsis_ref.to_yaml
      restored = Glossarist::ConceptRef.from_yaml(yaml)
      expect(restored.ellipsis?).to be(true)
    end

    it "omits external/ellipsis when false in serialized output" do
      yaml = resolved_ref.to_yaml
      expect(yaml).not_to match(/external/)
      expect(yaml).not_to match(/ellipsis/)
    end
  end

  describe "hyperedge helpers" do
    let(:hyperedge) do
      Glossarist::V3::GenericHyperedge.new(
        comprehensive: external_ref,
        members: [
          Glossarist::V3::GenericMember.new(ref: resolved_ref),
          Glossarist::V3::GenericMember.new(ref: external_ref),
          Glossarist::V3::GenericMember.new(ref: ellipsis_ref),
        ],
        criterion: { "eng" => "by type" },
      )
    end

    it "#has_external_comprehensive?" do
      expect(hyperedge.has_external_comprehensive?).to be(true)
    end

    it "#has_external_members?" do
      expect(hyperedge.has_external_members?).to be(true)
    end

    it "#inline_external_members returns external-tagged members" do
      ext = hyperedge.inline_external_members
      expect(ext.length).to eq(1)
    end

    it "#has_ellipsis_member?" do
      expect(hyperedge.has_ellipsis_member?).to be(true)
    end

    it "#ellipsis_members returns ellipsis-tagged members" do
      ell = hyperedge.ellipsis_members
      expect(ell.length).to eq(1)
    end
  end

  describe "HyperedgeWriter omits false flags" do
    let(:tmpdir) { Dir.mktmpdir }
    after { FileUtils.rm_rf(tmpdir) }

    it "writes clean YAML without external: false or ellipsis: false" do
      h = Glossarist::V3::GenericHyperedge.new(
        comprehensive: resolved_ref,
        members: [
          Glossarist::V3::GenericMember.new(ref: resolved_ref),
          Glossarist::V3::GenericMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          ),
        ],
        criterion: { "eng" => "by medium" },
      )
      path = Glossarist::V3::HyperedgeWriter.write(h, File.join(tmpdir, "relations"))
      content = File.read(path)
      expect(content).not_to match(/external: false/)
      expect(content).not_to match(/ellipsis: false/)
    end

    it "writes external: true when set" do
      h = Glossarist::V3::GenericHyperedge.new(
        comprehensive: resolved_ref,
        members: [
          Glossarist::V3::GenericMember.new(ref: external_ref),
          Glossarist::V3::GenericMember.new(
            ref: Glossarist::V3::ConceptRef.new(source: "VIM", id: "1.3"),
          ),
        ],
        criterion: { "eng" => "by medium" },
      )
      path = Glossarist::V3::HyperedgeWriter.write(h, File.join(tmpdir, "relations"))
      content = File.read(path)
      expect(content).to match(/external: true/)
    end

    it "writes ellipsis: true when set" do
      h = Glossarist::V3::GenericHyperedge.new(
        comprehensive: resolved_ref,
        members: [
          Glossarist::V3::GenericMember.new(ref: resolved_ref),
          Glossarist::V3::GenericMember.new(ref: ellipsis_ref),
        ],
        criterion: { "eng" => "by medium" },
      )
      path = Glossarist::V3::HyperedgeWriter.write(h, File.join(tmpdir, "relations"))
      content = File.read(path)
      expect(content).to match(/ellipsis: true/)
    end
  end
end
