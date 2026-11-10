# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe "mention tokens survive serialization" do
  # glossarist#275: the Psych-era emitter folded long plain scalars at
  # ~80 columns, occasionally landing inside a {{...}} mention token —
  # corrupt data at rest, since every downstream mention parser then sees
  # a different identifier than the authored one. The forced yeptris
  # lanes do not fold; this pins that.
  let(:mention_content) do
    "An **applied_attribute_classification_assignment** is a type of " \
      "{{urn:iso:std:iso:10303:-2:tech:doc:express:classification_schema}}, " \
      "that represents the application of a value, represented by " \
      "{{bib:express:classification_schema.class,class}}, to an attribute " \
      "on an EXPRESS entity."
  end

  it "writes mention-bearing content on a single unwrapped line" do
    model = Class.new(Lutaml::Model::Serializable) do
      attribute :content, Lutaml::Model::Type::String
    end.new(content: mention_content)

    dumped = model.to_yaml
    expect(dumped.scan("{{").count).to eq(dumped.scan("}}").count)
    expect(dumped).to include("{{bib:express:classification_schema.class,class}}")
  end

  it "keeps mention tokens intact through add_concept and save_directory" do
    out = Dir.mktmpdir("mention-token")

    store = Glossarist::GlossaryStore.new
    l10n = Glossarist::LocalizedConcept.new(
      data: Glossarist::ConceptData.new(
        definition: [Glossarist::DetailedDefinition.new(content: mention_content)],
        language_code: "eng",
      ),
    )
    l10n.data.terms = [Glossarist::Designation::Expression.new(
      designation: "applied_attribute_classification_assignment",
      normative_status: "preferred",
    )]
    mc = Glossarist::ManagedConcept.new(
      data: Glossarist::ManagedConceptData.new(id: "aaa-111"),
    )
    mc.uuid = "aaa-111"
    mc.add_localization(l10n)

    store.add_concept(mc)
    store.save_directory(out)

    saved = File.read(File.join(out, "concepts", "aaa-111.yaml"))
    expect(saved).to include("{{bib:express:classification_schema.class,class}}")
    expect(saved.lines.none? do |line|
      line.scan("{{").count > line.scan("}}").count
    end).to be(true)

    FileUtils.remove_entry(out)
  end

  it "treats a missing localizations key as empty" do
    dir = Dir.mktmpdir("no-localizations")
    FileUtils.mkdir_p(File.join(dir, "concepts"))
    File.write(File.join(dir, "concepts", "b.yaml"),
               "---\nid: b\ndata:\n  identifier: b\n")
    File.write(File.join(dir, "register.yaml"), "---\nshortname: t\n")

    store = Glossarist::GlossaryStore.new
    store.load_directory(dir)

    expect { store.concept("b") }.not_to raise_error
    expect(store.concept("b").uuid).to eq("b")

    FileUtils.remove_entry(dir)
  end
end
