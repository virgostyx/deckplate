require "spec_helper"

# No preview may overflow horizontally on a phone (375 px): content wraps, truncates or scrolls inside its own region.
RSpec.describe "No horizontal overflow at 375px", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    page.current_window.resize_to(375, 800)
  end

  OverflowHelper::ALL_PREVIEWS.call.reject { OverflowHelper::DESKTOP_ONLY.include?(_1) }.each do |preview|
    it "#{preview} fits in 375px" do
      visit "/rails/view_components/#{preview}"
      expect(page).to have_css("html[data-dp-theme]")
      overflowing = overflowing_elements
      expect(overflowing).to eq([]), "elements wider than the screen:\n  #{overflowing.join("\n  ")}"
    end
  end
end
