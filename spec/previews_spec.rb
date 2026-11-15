require "spec_helper"

RSpec.describe "Lookbook previews", type: :component do
  let(:stops) { YAML.load_file(Deckplate::Engine.root.join("config/deckplate/palette.yml")).fetch("stops").keys }

  describe TokenGalleryPreview do
    before { render_preview(:default, from: described_class) }

    it "shows every palette stop with its name and hex" do
      stops.each { |name| expect(page).to have_css("[data-token='stop-#{name}']", text: name) }
    end

    it "shows every role and the surface tokens" do
      Deckplate::Concerns::Colorable::ROLES.each { |r| expect(page).to have_css("[data-token='role-#{r}']", text: r.to_s) }
      %w[canvas surface surface-raised ink ink-muted line focus].each { |t| expect(page).to have_css("[data-token='surface-#{t}']") }
    end

    it "shows the type scale and the spacing scale" do
      expect(page).to have_css("[data-token='font-display']")
      expect(page).to have_css("[data-token='font-data']")
      expect(page).to have_css("[data-token='font-text']")
      expect(page).to have_css("[data-token^='space-']", minimum: 5)
    end
  end

  describe ThemeComparisonPreview do
    before { render_preview(:default, from: described_class) }

    it "renders one scoped sample per enabled theme" do
      Deckplate.configuration.themes.each do |t|
        expect(page).to have_css(".dp-root[data-dp-theme='#{t}'] [data-token='role-primary']")
      end
    end
  end
end
