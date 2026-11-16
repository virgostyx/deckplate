require "spec_helper"
require_relative "../tools/css_builder"

RSpec.describe DeckplateBuild::CssBuilder do
  let(:root) { Deckplate::Engine.root }

  it "keeps every generated file in sync with its sources (run bin/build-css if this fails)" do
    described_class.new(root).build.each do |path, content|
      expect(File.read(root.join(path))).to eq(content), "#{path} is stale: run bin/build-css"
    end
  end

  describe "per-family sheets (ADR 0012)" do
    let(:css_dir) { root.join("app/assets/stylesheets") }
    let(:families) { %w[controls forms data feedback] }
    let(:prelude) { File.read(css_dir.join("deckplate/layers.css")).strip }
    let(:parts) { described_class.new(root).build }

    def sheet(name) = File.read(css_dir.join("deckplate-#{name}.css"))
    def without_prelude(css) = css.sub(File.read(css_dir.join("deckplate/layers.css")).then { |l| l.gsub(%r{/\*.*?\*/}m, "").strip }, "").lstrip

    it "ships a core sheet and one sheet per family, next to the all-in-one deckplate.css" do
      (%w[core] + families).each { |name| expect(css_dir.join("deckplate-#{name}.css")).to exist }
    end

    it "starts every sheet with the layer prelude, so that they can be loaded in any order (ADR 0003)" do
      (%w[core] + families).each do |name|
        expect(sheet(name)).to start_with("@layer theme, base, dp, components, utilities;\n@layer dp.tokens"), "#{name} lacks the prelude"
      end
    end

    it "partitions the all-in-one bundle: core + families, in that order, lose nothing and duplicate nothing" do
      joined = ([ without_prelude(sheet("core")) ] + families.map { without_prelude(sheet(_1)) }).join("\n")
      all_in_one = without_prelude(File.read(css_dir.join("deckplate.css")))
      expect(joined.gsub(/\s+/, "")).to eq(all_in_one.gsub(/\s+/, ""))
    end

    it "keeps the family sheets to component rules (the tokens, themes and base live in core only)" do
      families.each do |name|
        body = without_prelude(sheet(name))
        expect(body).not_to include("@font-face")
        expect(body).not_to match(/\[data-dp-theme/)
        expect(body.scan(/^@layer ([\w.]+)/).flatten.uniq).to eq([ "dp.components" ]), "#{name} uses another layer than dp.components"
      end
    end

    # A rule belongs to the block of its first class (`.dp-button .dp-icon` is a button rule that mentions the icon).
    def subject_blocks(css)
      css.gsub(/@[\w-]+[^{;]*\{/) { |m| m.start_with?("@layer") ? "" : m } # drop at-rule preludes such as @media / @keyframes
         .scan(/([^{};]+)\{/).flatten.flat_map { |sel| sel.split(",") }
         .filter_map { |sel| sel[/\.(dp-[a-z0-9-]+?)(?:__|--|[^a-z0-9-]|\z)/, 1] }
         .reject { _1.match?(/\Adp-(c|v)-/) || %w[dp-root].include?(_1) }.uniq
    end

    it "does not style the same component in two sheets (each block is the subject of rules in one sheet only)" do
      owners = (%w[core] + families).flat_map { |name| subject_blocks(without_prelude(sheet(name))).map { [ _1, name ] } }
                                    .group_by(&:first).transform_values { |v| v.map(&:last).uniq }
      shared = owners.select { |_, names| names.size > 1 }
      expect(shared).to eq({}), "components styled by more than one sheet: #{shared.inspect}"
    end

    it "keeps the core free of component rules of a family (a family block never lives in core)" do
      family_blocks = families.flat_map { |name| subject_blocks(without_prelude(sheet(name))) }
      expect(subject_blocks(without_prelude(sheet("core"))) & family_blocks).to eq([])
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
