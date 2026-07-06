# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::OrphanedBibliographyRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-020")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when the bibliography index is empty" do
    expect(rule).not_to be_applicable(dataset_context)
  end

  context "with a bibliography.yaml and a concept that does not cite" do
    let(:dataset_context) do
      File.write(File.join(tmpdir, "bibliography.yaml"), <<~YAML, encoding: "utf-8")
        ---
        bibliography:
        - id: ISO_9000
          reference: ISO 9000
      YAML
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "x", langs: {
                                            eng: { definition: [{ "content" => "a definition with no xrefs" }] },
                                          }))
      ds
    end

    it "flags the bibliography entry as orphaned" do
      issues = rule.check(dataset_context)
      # The rule currently flags every entry when none are referenced
      # (the any? check in the loop short-circuits per entry).
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("ISO 9000")
    end
  end

  context "with a bibliography entry that a concept cites via <<anchor>>" do
    let(:dataset_context) do
      File.write(File.join(tmpdir, "bibliography.yaml"), <<~YAML, encoding: "utf-8")
        ---
        bibliography:
        - id: ISO_9000
          reference: ISO 9000
      YAML
      ds = make_dataset_context(tmpdir)
      ds.add_concept(make_managed_concept(id: "x", langs: {
                                            eng: { definition: [{ "content" => "See <<ISO_9000>> for context." }] },
                                          }))
      ds
    end

    it "returns no issues when the entry is cited" do
      issues = rule.check(dataset_context)
      expect(issues).to be_empty
    end
  end
end
