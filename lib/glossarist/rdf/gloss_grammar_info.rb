# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossGrammarInfo < Lutaml::Model::Serializable
      attribute :gender, :string, collection: true
      attribute :number, :string, collection: true
      attribute :part_of_speech, :string
      attribute :concept_id, :string
      attribute :lang_code, :string
      attribute :index, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |g| "concept/#{g.concept_id}/#{g.lang_code}/designation/#{g.index}/grammar" }

        types "gloss:GrammarInfo"

        predicate :gender, namespace: Namespaces::GlossaristNamespace, to: :gender, as: :uri
        predicate :number, namespace: Namespaces::GlossaristNamespace, to: :number, as: :uri
        predicate :isNoun, namespace: Namespaces::GlossaristNamespace, to: :noun?
        predicate :isVerb, namespace: Namespaces::GlossaristNamespace, to: :verb?
        predicate :isAdjective, namespace: Namespaces::GlossaristNamespace, to: :adjective?
        predicate :isAdverb, namespace: Namespaces::GlossaristNamespace, to: :adverb?
        predicate :isPreposition, namespace: Namespaces::GlossaristNamespace, to: :preposition?
        predicate :isParticiple, namespace: Namespaces::GlossaristNamespace, to: :participle?
      end

      def noun?
        part_of_speech == "noun"
      end

      def verb?
        part_of_speech == "verb"
      end

      def adjective?
        part_of_speech == "adjective"
      end

      def adverb?
        part_of_speech == "adverb"
      end

      def preposition?
        part_of_speech == "preposition"
      end

      def participle?
        part_of_speech == "participle"
      end
    end
  end
end
