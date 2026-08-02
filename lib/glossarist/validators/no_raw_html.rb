# frozen_string_literal: true

module Glossarist
  module Validators
    # Flags raw HTML in concept text that should be expressed as typed
    # mention syntax instead. Raw HTML bypasses the renderer, is
    # brittle, has no accessibility contract, and can embed
    # deployment-specific URLs.
    #
    # Suggested replacements:
    #
    #   <a href="URL">label</a>  → {{link:URL, label}}
    #   <a href="URL">URL</a>    → {{link:URL}}
    #   <img src="SRC">          → {{image:SRC}}
    #   <img src="SRC" alt="ALT">→ {{image:SRC, ALT}}
    #   <iframe src="URL">       → {{link:URL}}
    #
    # Usage:
    #   issues = Glossarist::Validators::NoRawHtml.call(concept_text)
    #   issues.each { |i| warn i[:message] }
    class NoRawHtml
      # Patterns are intentionally conservative — only tags that have
      # a direct typed-mention replacement. Other HTML tags (<b>, <i>,
      # <sup>, etc.) are left to the renderer's HTML sanitiser.
      LINK_PATTERN = /<a\s+href="([^"]+)"[^>]*>([^<]*)<\/a>/i.freeze
      IMAGE_PATTERN = /<img\s+src="([^"]+)"(?:\s+alt="([^"]*)")?[^>]*>/i.freeze
      IFRAME_PATTERN = /<iframe\s+src="([^"]+)"[^>]*>/i.freeze

      class << self
        # @param text [String] the concept text to check
        # @return [Array<Hash>] issues with severity, match, suggestion, message
        def call(text)
          return [] unless text.is_a?(String)

          [].tap do |issues|
            scan_links(text, issues)
            scan_images(text, issues)
            scan_iframes(text, issues)
          end
        end

        private

        def scan_links(text, issues)
          text.scan(LINK_PATTERN) do |url, label|
            suggestion = label && !label.strip.empty? ?
              "{{link:#{url}, #{label.strip}}}" :
              "{{link:#{url}}}"
            issues << {
              severity: "warning",
              match: %(<a href="#{url}">#{label}</a>),
              suggestion: suggestion,
              message: "Use {{link:#{url}}} instead of raw <a> tags",
            }
          end
        end

        def scan_images(text, issues)
          text.scan(IMAGE_PATTERN) do |src, alt|
            suggestion = alt && !alt.strip.empty? ?
              "{{image:#{src}, #{alt.strip}}}" :
              "{{image:#{src}}}"
            issues << {
              severity: "warning",
              match: %(<img src="#{src}"#{" alt=\"#{alt}\"" if alt}>),
              suggestion: suggestion,
              message: "Use {{image:#{src}}} instead of raw <img> tags",
            }
          end
        end

        def scan_iframes(text, issues)
          text.scan(IFRAME_PATTERN).each do |match|
            url = match.is_a?(Array) ? match[0] : match
            issues << {
              severity: "warning",
              match: %(<iframe src="#{url}">),
              suggestion: "{{link:#{url}}}",
              message: "iframes are not supported as embeds; use {{link:}} instead",
            }
          end
        end
      end
    end
  end
end
