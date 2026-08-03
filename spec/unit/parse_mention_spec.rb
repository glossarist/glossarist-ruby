# frozen_string_literal: true

require "spec_helper"

# The old Glossarist.parse_mention API has been superseded by
# Glossarist.parse_mentions (plural) + Glossarist::Mentions::Parser.
# See spec/unit/mentions/parser_spec.rb for the full test suite.
RSpec.describe "mention parser API" do
  it "exposes Glossarist.parse_mentions (plural)" do
    expect(Glossarist).to respond_to(:parse_mentions)
  end

  it "exposes Glossarist::Mentions::Parser" do
    expect(Glossarist::Mentions::Parser).to be_a(Module)
  end

  it "exposes Glossarist::Mentions::Resolver" do
    expect(Glossarist::Mentions::Resolver).to be_a(Module)
  end

  it "exposes Glossarist::Mentions::InvalidMentionError" do
    expect(Glossarist::Mentions::InvalidMentionError).to be_a(Class)
  end
end
