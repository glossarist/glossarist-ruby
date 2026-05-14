# frozen_string_literal: true

require "lutaml/turtle"
require "lutaml/jsonld"

require_relative "ext/mapping_ext"
require_relative "ext/mapping_rule_ext"
require_relative "ext/member_rule_ext"
require_relative "ext/turtle_transform_ext"
require_relative "ext/jsonld_transform_ext"

# Update Lutaml::Rdf::Mapping#predicate to pass through `as` option.
# Update Lutaml::Rdf::Mapping#members to pass through `inline` and `link` options.
Lutaml::Rdf::Mapping.class_eval do
  def predicate(name, namespace:, to:, lang_tagged: false, as: :literal)
    @rdf_predicates << Lutaml::Rdf::MappingRule.new(
      name,
      namespace: namespace,
      to: to,
      lang_tagged: lang_tagged,
      as: as,
    )
  end

  def members(attr_name, inline: true, link: nil)
    @rdf_members << Lutaml::Rdf::MemberRule.new(attr_name, inline: inline, link: link)
  end

  def deep_dup
    self.class.new.tap do |new_mapping|
      new_mapping.instance_variable_set(:@namespace_set, @namespace_set)
      new_mapping.instance_variable_set(:@rdf_subject, @rdf_subject)
      new_mapping.instance_variable_set(:@rdf_type, @rdf_type)
      if instance_variable_defined?(:@rdf_types) && @rdf_types
        new_mapping.instance_variable_set(:@rdf_types, @rdf_types.dup)
      end
      new_mapping.instance_variable_set(:@rdf_predicates, @rdf_predicates.dup)
      new_mapping.instance_variable_set(:@rdf_members, @rdf_members.dup)
    end
  end
end
