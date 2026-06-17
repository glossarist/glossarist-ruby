# frozen_string_literal: true

module Glossarist
  # One image variant within a Figure. Multiple variants enable responsive
  # images, format fallbacks, and accessibility (dark/light, language-specific).
  #
  # The `role` field drives consumer-side selection:
  #   vector  — SVG (preferred for diagrams, resolution-independent)
  #   raster  — PNG/JPG (preferred for photos)
  #   dark    — optimized for dark backgrounds
  #   light   — optimized for light backgrounds
  #   print   — high-resolution for print output
  class FigureImage < Lutaml::Model::Serializable
    attribute :src, :string
    attribute :format, :string
    attribute :role, :string
    attribute :width, :integer
    attribute :height, :integer
    attribute :scale, :integer

    key_value do
      map :src, to: :src
      map :format, to: :format
      map :role, to: :role
      map :width, to: :width
      map :height, to: :height
      map :scale, to: :scale
    end
  end
end
