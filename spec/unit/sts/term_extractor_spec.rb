# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/glossarist/sts"

RSpec.describe Glossarist::Sts::TermExtractor do
  let(:simple_fixture) do
    File.expand_path("../../fixtures/sts/simple_term.xml", __dir__)
  end

  let(:multi_lang_fixture) do
    File.expand_path("../../fixtures/sts/multi_lang_term.xml", __dir__)
  end

  let(:nested_symbol_fixture) do
    File.expand_path("../../fixtures/sts/nested_symbol.xml", __dir__)
  end

  describe "#extract" do
    context "with simple_term.xml" do
      subject { described_class.new(simple_fixture) }

      it "extracts two terms" do
        terms = subject.extract
        expect(terms.length).to eq(2)
      end

      it "extracts term IDs" do
        terms = subject.extract
        ids = terms.map(&:id)
        expect(ids).to contain_exactly("term_3.1", "term_3.2")
      end

      it "extracts labels" do
        terms = subject.extract
        labels = terms.map(&:label)
        expect(labels).to contain_exactly("3.1", "3.2")
      end

      it "extracts source reference from std-meta" do
        terms = subject.extract
        terms.each do |t|
          expect(t.source_ref).to eq("ISO 12345:2021")
        end
      end

      describe "first term (test robot)" do
        let(:term) { subject.extract.first }

        it "has one lang set" do
          expect(term.lang_sets.length).to eq(1)
        end

        it "maps language code to ISO 639-2" do
          expect(term.lang_sets.first.language_code).to eq("eng")
        end

        it "extracts definition text" do
          expect(term.lang_sets.first.definition_text).to eq("test robot definition")
        end

        it "extracts note texts" do
          expect(term.lang_sets.first.note_texts).to eq(["A note about the test robot."])
        end

        it "extracts example texts" do
          expect(term.lang_sets.first.example_texts).to eq(["An example of a test robot."])
        end

        it "extracts source texts" do
          expect(term.lang_sets.first.source_texts).to eq(["ISO 12345:2021, 3.1, modified"])
        end

        it "extracts designation" do
          desig = term.lang_sets.first.designations.first
          expect(desig.term).to eq("test robot")
          expect(desig.type).to eq("expression")
          expect(desig.normative_status).to eq("preferred")
          expect(desig.part_of_speech).to eq("noun")
        end
      end

      describe "second term (autonomy)" do
        let(:term) { subject.extract.last }

        it "extracts domain from subjectField" do
          expect(term.lang_sets.first.domain).to eq("robotics")
        end
      end
    end

    context "with multi_lang_term.xml" do
      subject { described_class.new(multi_lang_fixture) }

      it "extracts two terms" do
        expect(subject.extract.length).to eq(2)
      end

      describe "multi-lang term (machine)" do
        let(:term) do
          subject.extract.find { |t| t.id == "term_1.1" }
        end

        it "has two lang sets" do
          expect(term.lang_sets.length).to eq(2)
        end

        it "maps en to eng" do
          en_ls = term.lang_sets.find { |ls| ls.language_code == "eng" }
          expect(en_ls).not_to be_nil
        end

        it "maps fr to fra" do
          fr_ls = term.lang_sets.find { |ls| ls.language_code == "fra" }
          expect(fr_ls).not_to be_nil
        end

        it "extracts multiple designations per lang set" do
          en_ls = term.lang_sets.find { |ls| ls.language_code == "eng" }
          expect(en_ls.designations.length).to eq(2)
        end

        it "captures admitted normative status" do
          en_ls = term.lang_sets.find { |ls| ls.language_code == "eng" }
          admitted = en_ls.designations.find do |d|
            d.term == "mechanical device"
          end
          expect(admitted.normative_status).to eq("admitted")
        end

        it "extracts domain from subjectField" do
          en_ls = term.lang_sets.find { |ls| ls.language_code == "eng" }
          expect(en_ls.domain).to eq("engineering")
        end
      end

      describe "abbreviation term" do
        let(:term) do
          subject.extract.find { |t| t.id == "term_1.2" }
        end

        it "maps acronym term type to abbreviation" do
          acronym_desig = term.lang_sets.first.designations.find do |d|
            d.term == "AE"
          end
          expect(acronym_desig.type).to eq("abbreviation")
          expect(acronym_desig.abbreviation_type).to eq("acronym")
        end

        it "maps expression term type correctly" do
          expr_desig = term.lang_sets.first.designations.find do |d|
            d.term == "acronym example"
          end
          expect(expr_desig.type).to eq("expression")
        end
      end
    end

    context "with nested_symbol.xml" do
      subject { described_class.new(nested_symbol_fixture) }

      it "extracts terms from nested term-sec elements" do
        terms = subject.extract
        ids = terms.map(&:id)
        expect(ids).to include("term_3.1", "term_3.1.1", "term_3.2")
      end

      describe "symbol designation" do
        let(:term) do
          subject.extract.find { |t| t.id == "term_3.1" }
        end

        it "maps symbol term type to symbol" do
          sym_desig = term.lang_sets.first.designations.find do |d|
            d.term == "v"
          end
          expect(sym_desig.type).to eq("symbol")
        end
      end

      describe "deprecated normative status" do
        let(:term) do
          subject.extract.find { |t| t.id == "term_3.2" }
        end

        it "maps deprecatedTerm to deprecated" do
          desig = term.lang_sets.first.designations.first
          expect(desig.normative_status).to eq("deprecated")
        end
      end

      describe "nested term-sec" do
        let(:term) do
          subject.extract.find { |t| t.id == "term_3.1.1" }
        end

        it "extracts the nested term label" do
          expect(term.label).to eq("3.1.1")
        end

        it "extracts nested term data correctly" do
          expect(term.lang_sets.first.definition_text).to eq("the maximum velocity attainable")
        end
      end
    end
  end
end
