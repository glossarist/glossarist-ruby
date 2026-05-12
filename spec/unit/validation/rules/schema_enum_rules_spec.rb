# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DesignationStatusRule do
  subject(:rule) { described_class.new }

  def make_context(terms)
    l10n = instance_double(Glossarist::LocalizedConcept)
    allow(l10n).to receive(:language_code).and_return("eng")
    allow(l10n).to receive_message_chain(:data, :terms).and_return(terms)

    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:localizations).and_return([l10n])

    ctx = instance_double(Glossarist::Validation::Rules::ConceptContext)
    allow(ctx).to receive(:concept).and_return(concept)
    allow(ctx).to receive(:file_name).and_return("test.yaml")
    ctx
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-204")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "passes for valid normative_status" do
    term = Glossarist::Designation::Expression.new(
      designation: "test", normative_status: "preferred",
    )
    issues = rule.check(make_context([term]))
    expect(issues).to be_empty
  end

  it "reports invalid normative_status" do
    term = Glossarist::Designation::Expression.new(
      designation: "test", normative_status: "invalid_status",
    )
    issues = rule.check(make_context([term]))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("invalid normative_status")
  end

  it "skips nil normative_status" do
    term = Glossarist::Designation::Expression.new(designation: "test")
    issues = rule.check(make_context([term]))
    expect(issues).to be_empty
  end
end

RSpec.describe Glossarist::Validation::Rules::DateTypeRule do
  subject(:rule) { described_class.new }

  def make_context(dates, date_accepted = nil)
    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:dates).and_return(dates)
    allow(concept).to receive(:date_accepted).and_return(date_accepted)

    ctx = instance_double(Glossarist::Validation::Rules::ConceptContext)
    allow(ctx).to receive(:concept).and_return(concept)
    allow(ctx).to receive(:file_name).and_return("test.yaml")
    ctx
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-205")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "passes for valid date types" do
    date = Glossarist::ConceptDate.new(date: "2024-01-01", type: "accepted")
    issues = rule.check(make_context([date]))
    expect(issues).to be_empty
  end

  it "reports invalid date type" do
    date = Glossarist::ConceptDate.new(date: "2024-01-01", type: "invalid")
    issues = rule.check(make_context([date]))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("invalid type")
  end

  it "skips dates with no type" do
    date = Glossarist::ConceptDate.new(date: "2024-01-01")
    issues = rule.check(make_context([date]))
    expect(issues).to be_empty
  end

  it "checks date_accepted type" do
    da = Glossarist::ConceptDate.new(date: "2024-01-01", type: "invalid")
    issues = rule.check(make_context([], da))
    expect(issues.size).to eq(1)
  end
end

RSpec.describe Glossarist::Validation::Rules::LanguageCodeFormatRule do
  subject(:rule) { described_class.new }

  def make_context(lang_codes)
    l10ns = lang_codes.map do |code|
      l10n = instance_double(Glossarist::LocalizedConcept)
      allow(l10n).to receive(:language_code).and_return(code)
      l10n
    end

    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:localizations).and_return(l10ns)

    ctx = instance_double(Glossarist::Validation::Rules::ConceptContext)
    allow(ctx).to receive(:concept).and_return(concept)
    allow(ctx).to receive(:file_name).and_return("test.yaml")
    ctx
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-206")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "passes for valid 3-letter codes" do
    issues = rule.check(make_context(["eng", "fra", "deu"]))
    expect(issues).to be_empty
  end

  it "reports invalid language code" do
    issues = rule.check(make_context(["en"]))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("not a valid ISO 639-3 code")
  end

  it "reports uppercase language code" do
    issues = rule.check(make_context(["ENG"]))
    expect(issues.size).to eq(1)
  end

  it "skips nil language codes" do
    issues = rule.check(make_context([nil]))
    expect(issues).to be_empty
  end
end

RSpec.describe Glossarist::Validation::Rules::DesignationTypeRule do
  subject(:rule) { described_class.new }

  def make_context(terms)
    l10n = instance_double(Glossarist::LocalizedConcept)
    allow(l10n).to receive(:language_code).and_return("eng")
    allow(l10n).to receive_message_chain(:data, :terms).and_return(terms)

    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:localizations).and_return([l10n])

    ctx = instance_double(Glossarist::Validation::Rules::ConceptContext)
    allow(ctx).to receive(:concept).and_return(concept)
    allow(ctx).to receive(:file_name).and_return("test.yaml")
    ctx
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-207")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "passes for valid designation types" do
    term = Glossarist::Designation::Expression.new(designation: "test")
    issues = rule.check(make_context([term]))
    expect(issues).to be_empty
  end

  it "reports unknown designation type from hash" do
    term = { "type" => "unknown_type", "designation" => "test" }
    issues = rule.check(make_context([term]))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("unknown designation type")
  end

  it "passes for symbol designation" do
    term = Glossarist::Designation::Symbol.new(designation: "α")
    issues = rule.check(make_context([term]))
    expect(issues).to be_empty
  end
end

RSpec.describe Glossarist::Validation::Rules::DateValidityRule do
  subject(:rule) { described_class.new }

  def make_context(dates, date_accepted = nil)
    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:dates).and_return(dates)
    allow(concept).to receive(:date_accepted).and_return(date_accepted)

    ctx = instance_double(Glossarist::Validation::Rules::ConceptContext)
    allow(ctx).to receive(:concept).and_return(concept)
    allow(ctx).to receive(:file_name).and_return("test.yaml")
    ctx
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-307")
    expect(rule.category).to eq(:quality)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "passes for valid ISO 8601 dates" do
    date = Glossarist::ConceptDate.new(date: "2024-01-15", type: "accepted")
    issues = rule.check(make_context([date]))
    expect(issues).to be_empty
  end

  it "reports nil date when type is set" do
    date = Glossarist::ConceptDate.new(date: "not-a-date", type: "accepted")
    issues = rule.check(make_context([date]))
    expect(issues.size).to eq(1)
    expect(issues.first.message).to include("no date value")
  end

  it "skips nil dates without type" do
    date = Glossarist::ConceptDate.new(type: nil)
    issues = rule.check(make_context([date]))
    expect(issues).to be_empty
  end

  it "checks date_accepted" do
    da = Glossarist::ConceptDate.new(date: "not-a-date", type: "accepted")
    issues = rule.check(make_context([], da))
    expect(issues.size).to eq(1)
  end
end
