require "spec_helper"
require_relative "../tools/css_builder"

RSpec.describe DeckplateBuild::CssBuilder do
  let(:root) { Deckplate::Engine.root }

  it "keeps every generated file in sync with its sources (run bin/build-css if this fails)" do
    described_class.new(root).build.each do |path, content|
      expect(File.read(root.join(path))).to eq(content), "#{path} is stale: run bin/build-css"
    end
  end

  it "generates the quantised percentage classes dp-v-0 .. dp-v-100 used by the CSP-safe mode (SPEC section 11)" do
    values = described_class.new(root).build.fetch("app/assets/stylesheets/deckplate/values.css")
    (0..100).each { |n| expect(values).to include(".dp-v-#{n} { --dp-value: #{n}; }") }
    expect(values.scan(/\.dp-v-\d+ /).size).to eq(101)
    expect(File.read(root.join("app/assets/stylesheets/deckplate.css"))).to include(".dp-v-72{--dp-value:72;}".then { ".dp-v-72 { --dp-value: 72; }" })
  end

  it "ships the bundle without comments (sources keep them), and without runs of blank lines" do
    bundle = File.read(root.join("app/assets/stylesheets/deckplate.css"))
    expect(bundle).not_to match(%r{/\*})
    expect(bundle).not_to match(/\n{3,}/)
    expect(bundle).not_to match(/[ \t]+$/)
  end

  it "keeps the comments in the sources" do
    expect(File.read(root.join("app/assets/stylesheets/deckplate/shapes/elbow.css"))).to include("/*")
  end

  it "does not change what the CSS means: same rules once comments are removed" do
    sources = described_class.new(root).sources.map { |f| f.read.gsub(%r{/\*.*?\*/}m, "") }.join
    normalise = ->(css) { css.gsub(/\s+/, "") }
    expect(normalise.(File.read(root.join("app/assets/stylesheets/deckplate.css")))).to eq(normalise.(sources))
  end

  it "starts the bundle with the layer prelude" do
    bundle = File.read(root.join("app/assets/stylesheets/deckplate.css"))
    expect(bundle).to start_with("@layer theme, base, dp, components, utilities;")
  end

  it "generates a variable pair and a colour class for every palette stop and role" do
    tokens = described_class.new(root).build.fetch("app/assets/stylesheets/deckplate/tokens.css")
    palette = YAML.load_file(root.join("config/deckplate/palette.yml")).fetch("stops")
    palette.each do |name, stop|
      expect(tokens).to include("--dp-#{name}: #{stop['hex']};", "--dp-#{name}-ink: #{stop['ink']};", ".dp-c-#{name} {")
    end
    described_class::ROLES.each { |role| expect(tokens).to include(".dp-c-#{role} {") }
  end
end
