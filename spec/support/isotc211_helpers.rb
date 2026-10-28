# frozen_string_literal: true

module Isotc211Helpers
  def read_isotc211_yaml(path)
    YAML.safe_load(File.read(path, encoding: "utf-8"),
                   permitted_classes: [Time, Date])
  end

  # Legacy spellings and scalar types have canonical equivalents on output.
  # Compare the entire document so an unmapped field cannot silently disappear.
  def canonical_isotc211(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, item), result|
        case key
        when "dateAccepted"
          result["date_accepted"] = canonical_isotc211(item)
        when "release"
          result[key] = item.to_s
        when "clause"
          result["locality"] = { "type" => "clause", "reference_from" => item }
        else
          result[key] = canonical_isotc211(item)
        end
      end
    when Array
      value.map { |item| canonical_isotc211(item) }
    when Time, Date
      value.iso8601
    else
      value
    end
  end

  def expected_isotc211_document(path, localized: false)
    result = canonical_isotc211(read_isotc211_yaml(path))
    # Optional empty relationships are omitted by the model serializer.
    result.delete("related") if result["related"] == []
    if localized
      status = result.delete("status")
      result.fetch("data")["entry_status"] ||= status
    end
    result
  end
end
