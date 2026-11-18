require "spec_helper"

# A page served to a Hotwire Native client (user agent), checked in a real browser (ADR 0019).
RSpec.describe "Hotwire Native client", type: :system, js: true do
  NATIVE_AGENT = "MyApp Hotwire Native iOS; Turbo Native iOS; bridge-components: [];".freeze

  before { driven_by :dp_cuprite }

  def touch_emulation!
    pg = page.driver.browser.page
    pg.command("Emulation.setEmitTouchEventsForMouse", enabled: true, configuration: "mobile")
    pg.command("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 1)
  end

  def touch_min = page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--dp-touch-min').trim()")

  it "marks <html> and enlarges the touch targets to 48 px" do
    page.driver.browser.network.intercept(false) rescue nil
    page.driver.add_headers("User-Agent" => NATIVE_AGENT)
    touch_emulation!
    visit "/dashboard" # a page rendered with the application layout, which uses dp_theme_attrs
    expect(page).to have_css("html[data-dp-native='true']")
    expect(touch_min).to eq("3rem")
    height = page.evaluate_script("document.querySelector('#refresh').getBoundingClientRect().height")
    expect(height).to be >= 48
  end

  it "does nothing special for a browser" do
    visit "/dashboard"
    expect(page).to have_css("html[data-dp-theme]")
    expect(page).not_to have_css("html[data-dp-native]")
    expect(touch_min).to eq("2.75rem")
  end
end
