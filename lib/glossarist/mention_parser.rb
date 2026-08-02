# frozen_string_literal: true

module Glossarist
  # Reference kinds produced by parse_mention for the unified
  # {{kind:target}} / {{kind:target, label}} mention syntax.
  #
  # The shape produced for each kind is the cross-library contract —
  # glossarist-js produces the same keys, same values, so concept-browser
  # can consume either library's output interchangeably without translation.
  module MentionKinds
    # {{link:URL}} or {{link:URL, label}} — external URL link.
    # `uri` is canonical (deployment-independent); `label` is the display
    # text (nil means render the URL itself).
    LINK_REF = "link-ref"

    # {{image:src}} or {{image:src, alt}} — embedded image.
    # `src` is the image source; `alt` is accessibility text (nil means
    # no a11y label). Distinct from link-ref because it's an embed, not
    # a navigation link.
    IMAGE_REF = "image-ref"

    # {{bib:id}} or {{bib:id, label}} — dataset-local bibliography entry.
    # `id` references an entry in the dataset's bibliography.yaml. This is
    # the case-3-only path — the author explicitly wants a flat
    # bibliographic record, not a concept resolution.
    BIB_REF = "bib-ref"

    # {{cite:id}} or {{cite:id, label}} — concept citation.
    CITE_REF = "cite-ref"

    # {{fig:id}} / {{figure:id}} — non-concept figure entity xref.
    FIG_REF = "fig-ref"

    # {{table:id}} / {{tbl:id}} — non-concept table entity xref.
    TABLE_REF = "table-ref"

    # {{formula:id}} / {{eq:id}} — non-concept formula entity xref.
    FORMULA_REF = "formula-ref"

    # {{123}} or {{123, label}} — local concept by numeric id.
    LOCAL_CONCEPT_REF = "local-concept-ref"

    # {{designation}} — concept by designation text.
    DESIGNATION_REF = "designation-ref"

    # {{urn:...}} — URN reference.
    URN_REF = "urn-ref"
  end

  # Parsed mention result — a plain Hash with symbol keys. Built by
  # Glossarist.parse_mention. The shape per kind is documented on
  # MentionKinds constants above.
  #
  # Examples:
  #
  #   Glossarist.parse_mention("{{link:https://example.com, click here}}")
  #   # => { kind: "link-ref", uri: "https://example.com", label: "click here" }
  #
  #   Glossarist.parse_mention("{{image:diagram.png, The diagram}}")
  #   # => { kind: "image-ref", src: "diagram.png", alt: "The diagram" }
  #
  #   Glossarist.parse_mention("{{bib:ref_1, ISO 704}}")
  #   # => { kind: "bib-ref", id: "ref_1", label: "ISO 704" }
  module MentionParser
    module_function

    # Parse a single {{...}} mention into a canonical Hash.
    #
    # Returns nil if the input is not a valid mention string.
    # Raises ArgumentError if the mention is malformed (e.g., unknown
    # kind prefix).
    def parse_mention(text)
      return nil unless text.is_a?(String)

      match = text.match(/\A\s*\{\{([^}]+)\}\}\s*\z/)
      return nil unless match

      content = match[1].strip
      parse_content(content)
    end

    # Parse the inside of a {{...}} mention (without the braces).
    def parse_content(content)
      content = content.to_s.strip
      return nil if content.empty?

      identifier, label = split_identifier_and_label(content)
      dispatch_by_identifier(identifier, label)
    end

    def split_identifier_and_label(content)
      return [content, nil] unless content.include?(",")

      parts = content.split(",", 2)
      [parts[0].strip, parts[1].to_s.strip]
    end
    private_class_method :split_identifier_and_label

    def dispatch_by_identifier(identifier, label)
      case identifier
      when /\Alink:/i   then parse_link(identifier, label)
      when /\Aimage:/i  then parse_image(identifier, label)
      when /\Abib:/i    then parse_bib(identifier, label)
      when /\Acite:/i   then parse_cite(identifier, label)
      when /\A(fig|figure):/i  then parse_entity(identifier, label, MentionKinds::FIG_REF, "fig:")
      when /\A(table|tbl):/i   then parse_entity(identifier, label, MentionKinds::TABLE_REF, "table:")
      when /\A(formula|eq):/i  then parse_entity(identifier, label, MentionKinds::FORMULA_REF, "formula:")
      when /\Aurn:/i    then parse_urn(identifier, label)
      when /\A\d[\d.-]*\z/     then parse_local_concept(identifier, label)
      else parse_designation(identifier, label)
      end
    end
    private_class_method :dispatch_by_identifier

    def strip_label(label)
      label.nil? || label.empty? ? nil : label
    end
    private_class_method :strip_label

    def parse_link(identifier, label)
      uri = identifier.sub(/\Alink:/i, "").strip
      { kind: MentionKinds::LINK_REF, uri: uri, label: strip_label(label) }
    end
    private_class_method :parse_link

    def parse_image(identifier, label)
      src = identifier.sub(/\Aimage:/i, "").strip
      { kind: MentionKinds::IMAGE_REF, src: src, alt: strip_label(label) }
    end
    private_class_method :parse_image

    def parse_bib(identifier, label)
      id = identifier.sub(/\Abib:/i, "").strip
      { kind: MentionKinds::BIB_REF, id: id, label: strip_label(label) }
    end
    private_class_method :parse_bib

    def parse_cite(identifier, label)
      id = strip_quote_wrapping(identifier.sub(/\Acite:/i, "").strip)
      { kind: MentionKinds::CITE_REF, id: id, label: strip_label(label) }
    end
    private_class_method :parse_cite

    def parse_entity(identifier, label, kind, prefix)
      id = identifier.sub(/\A(?:fig|figure|table|tbl|formula|eq):/i, "").strip
      { kind: kind, id: id, label: strip_label(label) }
    end
    private_class_method :parse_entity

    def parse_urn(identifier, label)
      { kind: MentionKinds::URN_REF, urn: identifier, label: strip_label(label) }
    end
    private_class_method :parse_urn

    def parse_local_concept(identifier, label)
      { kind: MentionKinds::LOCAL_CONCEPT_REF, id: identifier, label: strip_label(label) }
    end
    private_class_method :parse_local_concept

    def parse_designation(identifier, label)
      { kind: MentionKinds::DESIGNATION_REF, designation: label || identifier }
    end
    private_class_method :parse_designation

    # cite: identifiers may be wrapped in double quotes; the wrapping
    # is removed and the doubled "“”" inside unescaped.
    def strip_quote_wrapping(s)
      return s unless s.start_with?('"') && s.end_with?('"') && s.length >= 2

      s[1..-2].gsub('""', '"')
    end
    private_class_method :strip_quote_wrapping
  end
end
