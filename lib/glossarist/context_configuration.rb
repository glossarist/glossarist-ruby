# frozen_string_literal: true

module Glossarist
  module ContextConfiguration
    def context_id
      self::CONTEXT_ID
    end

    def context
      Lutaml::Model::GlobalContext.context(context_id)
    end

    def create_context(
      id:,
      registry: nil,
      fallback_to: [context_id],
      substitutions: []
    )
      normalized_id = id.to_sym

      return populate_context! if normalized_id == context_id

      Lutaml::Model::GlobalContext.unregister_context(normalized_id) if Lutaml::Model::GlobalContext.context(normalized_id)
      create_type_context(
        id: normalized_id,
        registry: registry || Lutaml::Model::TypeRegistry.new,
        fallback_to: normalize_fallbacks(fallback_to),
        substitutions: substitutions,
      )
    end

    def populate_context!
      Lutaml::Model::GlobalContext.unregister_context(context_id) if context
      register_models_in(base_type_context)
    end

    def register_model(klass, id:)
      normalized_id = id.to_sym
      registered_models[normalized_id] = klass
      (context || populate_base_context).registry.register(normalized_id, klass)
      klass
    end

    def resolve_model(id)
      Lutaml::Model::GlobalContext.resolve_type(id, context_id)
    end

    private

    def populate_base_context
      base_type_context
    end

    def create_type_context(id:, registry:, fallback_to:, substitutions: [])
      Lutaml::Model::GlobalContext.create_context(
        id: id,
        registry: registry,
        fallback_to: fallback_to,
        substitutions: substitutions,
      ).tap do
        Lutaml::Model::GlobalContext.clear_caches
      end
    end

    def base_type_context
      create_type_context(
        id: context_id,
        registry: Lutaml::Model::TypeRegistry.new,
        fallback_to: [:default],
      )
    end

    def register_models_in(type_context)
      registered_models.each do |model_id, klass|
        type_context.registry.register(model_id, klass)
      end

      Lutaml::Model::GlobalContext.clear_caches
      type_context
    end

    def normalize_fallbacks(fallback_to)
      Array(fallback_to).map(&:to_sym)
    end

    def registered_models
      @registered_models ||= {}
    end
  end
end
