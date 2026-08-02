# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validators::NoRawHtml do
  describe ".call" do
    it "returns empty for clean text" do
      expect(described_class.call("A clean definition.")).to eq([])
    end

    it "returns empty for non-String input" do
      expect(described_class.call(nil)).to eq([])
      expect(described_class.call(123)).to eq([])
    end

    it "flags <a href> with label" do
      issues = described_class.call('See <a href="http://example.com">Example</a> for details.')
      expect(issues.length).to eq(1)
      expect(issues[0][:suggestion]).to eq("{{link:http://example.com, Example}}")
      expect(issues[0][:severity]).to eq("warning")
    end

    it "flags <a href> without meaningful label → {{link:URL}}" do
      issues = described_class.call('<a href="http://example.com"></a>')
      expect(issues[0][:suggestion]).to eq("{{link:http://example.com}}")
    end

    it "flags <img src> without alt → {{image:SRC}}" do
      issues = described_class.call('<img src="diagram.png">')
      expect(issues[0][:suggestion]).to eq("{{image:diagram.png}}")
    end

    it "flags <img src alt> → {{image:SRC, ALT}}" do
      issues = described_class.call('<img src="diagram.png" alt="The diagram">')
      expect(issues[0][:suggestion]).to eq("{{image:diagram.png, The diagram}}")
    end

    it "flags <iframe src> → {{link:URL}}" do
      issues = described_class.call('<iframe src="https://youtube.com/embed/x"></iframe>')
      expect(issues.length).to eq(1)
      expect(issues[0][:suggestion]).to eq("{{link:https://youtube.com/embed/x}}")
      expect(issues[0][:message]).to include("not supported as embeds")
    end

    it "flags multiple HTML tags in one text" do
      text = 'See <a href="http://x.io">link</a> and <img src="img.png" alt="alt">'
      issues = described_class.call(text)
      expect(issues.length).to eq(2)
    end

    it "is case-insensitive on tag names" do
      issues = described_class.call('<A HREF="http://x.io">label</A>')
      expect(issues.length).to eq(1)
    end
  end
end
