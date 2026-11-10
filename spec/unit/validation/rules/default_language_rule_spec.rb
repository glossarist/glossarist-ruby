# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DefaultLanguageRule do
  let(:rule) { described_class.new }

  def context_for(concept, file_name = "test.yaml")
    ds = Glossarist::Validation::Rules::DatasetContext.new(Dir.mktmpdir("dlr"))
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: file_name, collection_context: ds
    )
  end

  def concept_with_langs(*langs)
    mc = Glossarist::ManagedConcept.new(
      data: Glossarist::ManagedConceptData.new(id: "c-1"),
    )
    mc.uuid = "c-1"
    langs.each do |lang|
      mc.add_localization(Glossarist::LocalizedConcept.new(
                            language_code: lang,
                            data: Glossarist::ConceptData.new(language_code: lang),
                          ))
    end
    mc
  end

  around do |example|
    original = Glossarist::Config.instance.default_language
    example.run
  ensure
    Glossarist::Config.instance.default_language = original
  end

  it "is registered and carries its code" do
    expect(Glossarist::Validation::Rules::Registry.all).to include(described_class)
    expect(rule.code).to eq("GLS-311")
  end

  it "passes when the default-language localization exists" do
    issues = rule.check(context_for(concept_with_langs("eng", "fra")))
    expect(issues).to be_empty
  end

  it "flags a concept missing the default-language localization" do
    issues = rule.check(context_for(concept_with_langs("fra", "deu")))
    expect(issues.length).to eq(1)
    expect(issues.first.severity).to eq("error")
    expect(issues.first.message).to include("'eng'")
    expect(issues.first.message).to include("fra, deu")
  end

  it "skips concepts with no localizations at all" do
    issues = rule.check(context_for(concept_with_langs))
    expect(issues).to be_empty
  end

  it "honors a customized default language" do
    Glossarist::Config.instance.default_language = "deu"

    issues = rule.check(context_for(concept_with_langs("fra", "deu")))
    expect(issues).to be_empty

    issues = rule.check(context_for(concept_with_langs("eng", "fra")))
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("'deu'")
  end

  it "reads default_language from ManagedConcept#default_lang" do
    Glossarist::Config.instance.default_language = "deu"
    mc = concept_with_langs("fra", "deu")
    expect(mc.default_lang.language_code).to eq("deu")
  end
end
