require "spec_helper"

RSpec.describe "I18n" do
  def flatten(hash, prefix = nil)
    hash.flat_map do |k, v|
      key = [ prefix, k ].compact.join(".")
      v.is_a?(Hash) ? flatten(v, key).to_a : [ [ key, v ] ]
    end.to_h
  end

  let(:root) { Deckplate::Engine.root.join("config/locales") }
  let(:en) { flatten(YAML.load_file(root.join("en.yml")).fetch("en")) }
  let(:fr) { flatten(YAML.load_file(root.join("fr.yml")).fetch("fr")) }

  it "keeps all keys under the deckplate.* scope" do
    expect((en.keys + fr.keys).reject { _1.start_with?("deckplate.") }).to eq([])
  end

  it "has exactly the same keys in en and fr" do
    expect(en.keys - fr.keys).to eq([]), "missing in fr: #{(en.keys - fr.keys).inspect}"
    expect(fr.keys - en.keys).to eq([]), "missing in en: #{(fr.keys - en.keys).inspect}"
  end

  it "has no blank translations" do
    expect(en.select { |_, v| v.to_s.strip.empty? }.keys).to eq([])
    expect(fr.select { |_, v| v.to_s.strip.empty? }.keys).to eq([])
  end

  it "uses the same interpolation variables in both languages" do
    vars = ->(s) { s.to_s.scan(/%\{(\w+)\}/).flatten.sort }
    mismatched = en.keys.select { |k| vars.(en[k]) != vars.(fr[k]) }
    expect(mismatched).to eq([])
  end

  it "resolves through I18n in both locales" do
    I18n.with_locale(:en) { expect(I18n.t("deckplate.common.close")).to eq("Close") }
    I18n.with_locale(:fr) { expect(I18n.t("deckplate.common.close")).to eq("Fermer") }
  end

  it "is loaded by the engine for both locales" do
    expect(I18n.available_locales).to include(:en, :fr)
  end
end
