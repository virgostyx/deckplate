require "spec_helper"

# The bridge is a template of the installer (ADR 0016): copied to the host as app/assets/tailwind/deckplate-bridge.css and imported by its
# Tailwind source, which gives `bg-dp-primary`, `text-dp-ink`, ...
RSpec.describe "Tailwind bridge" do
  let(:path) { Deckplate::Engine.root.join("lib/generators/deckplate/install/templates/tailwind_bridge.css") }
  let(:css) { File.read(path) }
  let(:roles) { %w[primary secondary tertiary accent muted info success warning danger emergency] }
  let(:neutrals) { %w[canvas surface surface-raised ink ink-muted line focus disabled] }

  it "maps every role, its ink and every neutral to a Tailwind colour, by reference (so themes keep working)" do
    (roles.flat_map { [ _1, "#{_1}-ink" ] } + neutrals).each do |name|
      expect(css).to match(/--color-dp-#{Regexp.escape(name)}:\s*var\(--dp-#{Regexp.escape(name)}\);/), "missing #{name}"
    end
  end

  it "maps the three font families" do
    %w[display data text].each { expect(css).to match(/--font-dp-#{_1}:\s*var\(--dp-font-#{_1}\);/) }
  end

  it "uses @theme inline (values stay live CSS variables) and nothing else" do
    expect(css).to include("@theme inline {")
    expect(css.gsub(%r{/\*.*?\*/}m, "").gsub(/@theme inline \{.*\}/m, "").strip).to eq("")
  end

  it "does not ship an engine.css (tailwindcss-rails would write an absolute-path import that the browser requests, ADR 0016)" do
    expect(Deckplate::Engine.root.join("app/assets/tailwind")).not_to exist
  end

  it "is shipped in the gem" do
    spec = Gem::Specification.load(Deckplate::Engine.root.join("deckplate.gemspec").to_s)
    expect(spec.files).to include("lib/generators/deckplate/install/templates/tailwind_bridge.css")
  end
end
