#!/usr/bin/env ruby

require "optparse"
require "glossarist"

options = {}

OptionParser.new do |opt|
  opt.on('-n', '--new_concept_path NEW_CONCEPT_PATH') do |o|
    options[:new_concept_path] = o
  end
  opt.on('-o', '--old_concept_path OLD_CONCEPT_PATH') do |o|
    options[:old_concept_path] = o
  end
  opt.on("-c", "--[no-]color [FLAG]", TrueClass, "Colorize differences") do |o|
    options[:color] = o.nil? ? true : o
  end
end.parse!

def load_concepts(dataset_concept_path)
  collection = Glossarist::ManagedConceptCollection.new
  collection.load_from_files(dataset_concept_path)
  collection
end

def compare_file_counts(new_concepts, old_concepts, output_content)
  new_count = new_concepts.managed_concepts.count
  old_count = old_concepts.managed_concepts.count

  output_content << "Comparing concept counts:"
  output_content << "-" * 40
  output_content << "New concepts: #{new_count} | " \
                    "Old concepts: #{old_count}"

  diff = new_count - old_count
  if diff > 0
    output_content << "New concepts added: #{diff}"
  elsif diff < 0
    output_content << "Old concepts removed: #{-diff}"
  else
    output_content << "No change in concept counts."
  end

  output_content << "-" * 40
end

def compare_mapped_concepts(new_concepts, old_concepts, output_content)
  output_content << "Comparing concepts:"
  output_content << "-" * 40

  new_concepts.each do |new_concept|
    old_concept = find_concept_by_id(old_concepts, new_concept.id)

    if old_concept
      diff_score, diff_tree = Lutaml::Model::Serialize.diff_with_score(
        new_concept,
        old_concept,
        show_unchanged: false,
        highlight_diff: true,
        use_colors: false,
        indent: "",
      )
      similarity_percentage = (1 - diff_score) * 100

      output_content << "Diff Tree of #{new_concept.id} with " \
                        "Similarity score: #{similarity_percentage.round(2)}%:"
      output_content << "-" * 30
      output_content << diff_tree
      output_content << "-" * 30
    end
  end

  output_content << "-" * 40
end

def show_mapping(new_concepts, old_concepts, output_content)
  output_content << "Mapping new concepts to old concepts:"
  output_content << "-" * 40

  # find the mapping of new concepts to old concepts
  not_mapped_new_ids = []
  new_concepts.each do |concept|
    mapped_old_concept = find_concept_by_id(old_concepts, concept.id)

    if mapped_old_concept
      output_content << "#{concept.id} | #{mapped_old_concept.id}"
    else
      not_mapped_new_ids << concept.id
    end
  end

  # find the mapping of old concepts to new concepts
  not_mapped_old_ids = []
  old_concepts.each do |concept|
    mapped_new_concepts = find_concept_by_id(new_concepts, concept.data.id)

    if mapped_new_concepts.nil?
      not_mapped_old_ids << concept.data.id
    end
  end

  unless not_mapped_new_ids.empty?
    output_content << "-" * 40
    output_content << "Not mapped new concepts (count: #{not_mapped_new_ids.count}):"
    output_content << "-" * 40
    not_mapped_new_ids.each do |id|
      output_content << id
    end
  end

  unless not_mapped_old_ids.empty?
    output_content << "-" * 40
    output_content << "Not mapped old concepts (count: #{not_mapped_old_ids.count}):"
    output_content << "-" * 40
    not_mapped_old_ids.each do |id|
      output_content << id
    end
  end

  output_content << "-" * 40
end

def find_concept_by_id(old_concepts, id)
  old_concepts.find do |concept|
    concept.data.id == id
  end
end

def compare_concepts(new_concepts, old_concepts, output_content)
  compare_file_counts(new_concepts, old_concepts, output_content)
  show_mapping(new_concepts, old_concepts, output_content)
  compare_mapped_concepts(new_concepts, old_concepts, output_content)
end

def output(content, use_color_codes: true)
  # add a newline at the end of the content
  content << ""

  File.open("compare_report.txt", "w") do |file|
    file.write(
      content.map do |line|
        if use_color_codes
          line.to_s
        else
          # remove color codes
          line.to_s.gsub(/\e\[\d+m/, '')
        end
      end.join("\n")
    )
  end
end

def main(options)
  options[:color] = true if options[:color].nil?
  # puts options

  new_dataset_concept_path = options[:new_concept_path]
  old_dataset_concept_path = options[:old_concept_path]

  if new_dataset_concept_path.nil? || old_dataset_concept_path.nil?
    puts "Please provide both new and old dataset concept paths " \
         "using -n and -o options."
    exit 1
  end

  new_concepts = load_concepts(new_dataset_concept_path)
  old_concepts = load_concepts(old_dataset_concept_path)

  output_content = []
  compare_concepts(new_concepts, old_concepts, output_content)

  output(output_content, use_color_codes: options[:color])
end

main(options)