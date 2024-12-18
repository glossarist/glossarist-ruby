module Glossarist
  class Asset < Lutaml::Model::Serializable
    attribute :path, :string

    yaml do
      map :path, to: :path
    end

    def eql?(asset)
      path == asset.path
    end
  end
end
