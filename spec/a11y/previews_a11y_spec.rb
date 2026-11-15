require "spec_helper"
# Every Lookbook preview example, in every theme, must have zero WCAG 2.2 AA violations (SPEC section 12).
RSpec.describe "Accessibility of previews", type: :system, js: true do
  before { driven_by :dp_cuprite }

  examples = ViewComponent::Preview.all.flat_map { |p| p.examples.map { |e| "#{p.preview_name}/#{e}" } }.sort

  examples.each do |preview|
    Deckplate::Configuration::BUILT_IN_THEMES.each do |theme|
      it "#{preview} has no axe violations in #{theme}" do
        visit "/rails/view_components/#{preview}?_display=#{ERB::Util.url_encode({ theme: theme }.to_json)}"
        expect(page).to have_css("html[data-dp-theme='#{theme}']")
        violations = axe_violations
        expect(violations).to be_empty, "axe violations:\n#{axe_report(violations)}"
      end
    end
  end
end
