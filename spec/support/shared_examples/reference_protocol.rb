# frozen_string_literal: true

# Shared contract for every class that includes Glossarist::Reference.
#
# The protocol guarantees that validation rules iterating a mixed collection
# of references (e.g. CiteRefIntegrityRule's `select(&:cite?)`) can call any
# predicate on any member without type-checking. This shared example asserts
# the contract: the three predicates exist and return a boolean.
#
# ConceptReference overrides the predicates with state-dependent semantics,
# so it does not include this shared example — its behavior is verified in
# spec/unit/reference_spec.rb and spec/unit/concept_reference_spec.rb.
RSpec.shared_examples "a Glossarist::Reference" do
  describe "Reference protocol" do
    it "responds to cite?" do
      expect(subject).to respond_to(:cite?)
    end

    it "responds to local?" do
      expect(subject).to respond_to(:local?)
    end

    it "responds to external?" do
      expect(subject).to respond_to(:external?)
    end

    it "returns a boolean from cite?" do
      expect([true, false]).to include(subject.cite?)
    end

    it "returns a boolean from local?" do
      expect([true, false]).to include(subject.local?)
    end

    it "returns a boolean from external?" do
      expect([true, false]).to include(subject.external?)
    end
  end
end
