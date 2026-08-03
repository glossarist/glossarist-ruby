# frozen_string_literal: true

module Glossarist
  module Mentions
    # Scans a string for {{kind:target}} patterns and returns a mixed
    # array of text segments and parsed mention objects.
    #
    # Invalid mentions raise InvalidMentionError — they are never
    # silently passed through.
    #
    # @see concept-model docs/design/inline-mentions.md
    module Parser
      MENTION_REGEX = /\{\{([^}]+)\}\}/.freeze

      KINDS = %w[concept cite fig table formula bib link image].freeze

      module_function

      # @param text [String] the source text to scan
      # @return [Array<Hash>] segments — text and mention objects
      # @raise [InvalidMentionError] on invalid mention syntax
      def parse(text)
        return [{ kind: "text", content: "" }] unless text.is_a?(String) && !text.empty?

        segments = []
        pos = 0

        text.to_enum(:scan, MENTION_REGEX).each do |match|
          raw_content = match[0]
          match_start = Regexp.last_match.offset(0)[0]

          if match_start > pos
            segments << { kind: "text", content: text[pos...match_start] }
          end

          segment = parse_mention_content(
            raw_content,
            raw: "{{#{raw_content}}}",
            position: match_start,
          )
          segments << segment
          pos = Regexp.last_match.offset(0)[1]
        end

        segments << { kind: "text", content: text[pos..] } if pos < text.length
        segments
      end

      def parse_mention_content(content, raw:, position:)
        content = content.strip

        unless content =~ /\A(\w+):(.*)\z/m
          raise InvalidMentionError.new(
            raw: raw,
            position: position,
            reason: "Missing kind prefix; use {{concept:DATASET:ID}} or " \
                    "{{cite:DATASET:ID}} — got #{raw}",
          )
        end

        kind = Regexp.last_match(1).downcase
        rest = Regexp.last_match(2).strip

        unless KINDS.include?(kind)
          raise InvalidMentionError.new(
            raw: raw,
            position: position,
            reason: "Unknown kind '#{kind}'; valid kinds: #{KINDS.join(', ')}",
          )
        end

        target_str, label = split_target_and_label(rest)

        target = parse_target(target_str, kind: kind, raw: raw, position: position)

        validate_target!(kind, target, raw: raw, position: position)

        {
          kind: kind,
          target: target,
          label: strip_label(label),
          raw: raw,
          start: position,
          end: position + raw.length,
        }
      end

      def split_target_and_label(rest)
        return [rest, nil] unless rest.include?(",")

        parts = rest.split(",", 2)
        [parts[0].strip, parts[1].to_s.strip]
      end
      private_class_method :split_target_and_label

      def parse_target(target_str, kind:, raw:, position:)
        case target_str
        when /\Aurn:/i
          { type: "urn", urn: target_str }
        when /\Ahttps?:\/\//i
          { type: "url", url: target_str }
        when /\A[a-zA-Z][a-zA-Z0-9_-]*:[^:]+/
          split_dataset_qualified(target_str)
        when %r{\A[a-zA-Z0-9_./-]+\z}
          if target_str.include?("/")
            { type: "path", path: target_str }
          else
            { type: "entity_id", id: target_str }
          end
        else
          { type: "entity_id", id: target_str }
        end
      end
      private_class_method :parse_target

      def split_dataset_qualified(target_str)
        last_colon = target_str.rindex(":")
        dataset = target_str[0...last_colon]
        id = target_str[(last_colon + 1)..]
        { type: "dataset_qualified", dataset: dataset, id: id }
      end
      private_class_method :split_dataset_qualified

      def validate_target!(kind, target, raw:, position:)
        type = target[:type]

        case kind
        when "concept", "cite"
          unless %w[urn dataset_qualified].include?(type)
            raise InvalidMentionError.new(
              raw: raw,
              position: position,
              reason: "#{kind} target must be DATASET:ID or URN; " \
                      "got #{type} #{target_value_for_error(target).inspect}",
            )
          end
        when "fig", "table", "formula"
          unless %w[entity_id urn].include?(type)
            raise InvalidMentionError.new(
              raw: raw,
              position: position,
              reason: "#{kind} target must be plain ID or URN; " \
                      "got #{type} #{target_value_for_error(target).inspect}",
            )
          end
        when "bib"
          unless type == "entity_id"
            raise InvalidMentionError.new(
              raw: raw,
              position: position,
              reason: "bib target must be a plain ID (same-dataset); " \
                      "got #{type} #{target_value_for_error(target).inspect}",
            )
          end
        when "link"
          unless type == "url"
            raise InvalidMentionError.new(
              raw: raw,
              position: position,
              reason: "link target must be https:// or http:// URL; " \
                      "got #{target_value_for_error(target).inspect}",
            )
          end
        when "image"
          unless %w[path url].include?(type)
            raise InvalidMentionError.new(
              raw: raw,
              position: position,
              reason: "image target must be a path or URL; " \
                      "got #{type} #{target_value_for_error(target).inspect}",
            )
          end
        end
      end
      private_class_method :validate_target!

      def target_value_for_error(target)
        target[:urn] || target[:url] || target[:id] ||
          target[:dataset] ? "#{target[:dataset]}:#{target[:id]}" : target[:path]
      end
      private_class_method :target_value_for_error

      def strip_label(label)
        label.nil? || label.empty? ? nil : label
      end
      private_class_method :strip_label
    end
  end
end
