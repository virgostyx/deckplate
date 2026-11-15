require "spec_helper"

RSpec.describe "Controls behaviour", type: :system, js: true do
  before { driven_by :dp_cuprite }

  describe "Toggle" do
    before { visit "/rails/view_components/toggle/default" }

    it "toggles with a click on the label and with the space key" do
      input = find("input[role='switch']", visible: :all)
      expect(input).not_to be_checked
      find(".dp-toggle__label").click
      expect(input).to be_checked
      focus("input[role='switch']")
      press(:space)
      expect(input).not_to be_checked
    end

    it "shows a visible focus ring on the track when reached with the Tab key" do
      press(:Tab)
      expect(page.evaluate_script("document.activeElement.matches('.dp-toggle__input')")).to be(true)
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.dp-toggle__track')).outlineStyle")).to eq("solid")
    end
  end

  describe "Slider (dp-slider)" do
    before { visit "/rails/view_components/slider/default" }

    it "starts with the server-rendered value and the matching fill" do
      expect(page).to have_css("output", text: "72%")
      expect(page.evaluate_script("document.querySelector('.dp-slider').style.getPropertyValue('--dp-pct')")).to eq("72")
    end

    it "updates the readout and the fill as the value changes with the keyboard" do
      focus("input[type='range']")
      press(:Right, :Right)
      expect(page).to have_css("output", text: "74%")
      expect(page.evaluate_script("document.querySelector('.dp-slider').style.getPropertyValue('--dp-pct')")).to eq("74")
      press(:Home)
      expect(page).to have_css("output", text: "0%")
      press(:End)
      expect(page).to have_css("output", text: "100%")
    end

    it "is CSP safe: the server markup has no style attribute, the fill comes from a CSSOM custom property" do
      visit "/rails/view_components/slider/default"
      server_html = page.evaluate_script("document.documentElement.outerHTML").to_s
      expect(page.driver.browser.network.traffic.first.response.body).not_to match(/<[^>]+\sstyle=/)
      expect(server_html).to include("--dp-pct") # written by the controller after load
    end
  end
end
