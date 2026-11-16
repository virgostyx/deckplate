require "spec_helper"

RSpec.describe "Motion", type: :system, js: true do
  before { driven_by :dp_cuprite }

  def reduce_motion = page.driver.browser.page.command("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
  def style_of(selector, property) = page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
  def seconds(value) = value.to_s.split(",").first.to_f * (value.to_s.include?("ms") ? 0.001 : 1)

  describe "Frame entrance cascade (animate: true)" do
    before { page.current_window.resize_to(1280, 800) }

    it "is off by default" do
      visit "/rails/view_components/frame/classic"
      %w[.dp-frame__header .dp-frame__sidebar .dp-frame__main].each { expect(style_of(_1, "animationName")).to eq("none") }
    end

    it "reveals the header bar, then slides the sidebar, then fades the content in, in that order" do
      visit "/rails/view_components/frame/animated"
      names = %w[.dp-frame__header .dp-frame__sidebar .dp-frame__main].map { style_of(_1, "animationName") }
      expect(names).to eq(%w[dp-frame-reveal dp-frame-slide dp-frame-fade])
      delays = %w[.dp-frame__header .dp-frame__sidebar .dp-frame__main].map { seconds(style_of(_1, "animationDelay")) }
      expect(delays).to eq(delays.sort)
      expect(delays.first).to eq(0.0)
      durations = %w[.dp-frame__header .dp-frame__sidebar .dp-frame__main].map { seconds(style_of(_1, "animationDuration")) }
      expect(durations).to eq([ 0.3, 0.4, 0.5 ])
      expect(delays.last + durations.last).to be < 1.0 # the page is usable within a second
    end

    it "ends fully visible: nothing stays hidden after the cascade" do
      visit "/rails/view_components/frame/animated"
      sleep 1.3
      expect(style_of(".dp-frame__main", "opacity")).to eq("1")
      expect(style_of(".dp-frame__sidebar", "opacity")).to eq("1")
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.dp-frame__header')).clipPath")).to match(/\Anone\z|\Ainset\((0(px|%)?\s*){1,4}\)\z/)
    end

    it "is neutralised by prefers-reduced-motion: no delay, near-instant, a single iteration" do
      visit "/rails/view_components/frame/animated"
      reduce_motion
      %w[.dp-frame__header .dp-frame__sidebar .dp-frame__main].each do |selector|
        expect(seconds(style_of(selector, "animationDelay"))).to eq(0.0), "#{selector} keeps its delay"
        expect(seconds(style_of(selector, "animationDuration"))).to be <= 0.001
        expect(style_of(selector, "animationIterationCount")).to eq("1")
      end
      expect(style_of(".dp-frame__main", "opacity")).to eq("1") # not stuck invisible behind a delayed backwards-filled animation
    end

    it "does not move the layout (transform, opacity and clip-path only): the content stays put during the cascade" do
      visit "/rails/view_components/frame/animated"
      first = page.evaluate_script("document.querySelector('.dp-frame__main').getBoundingClientRect().top")
      sleep 0.2
      expect(page.evaluate_script("document.querySelector('.dp-frame__main').getBoundingClientRect().top")).to eq(first)
    end
  end

  describe "Readout flicker (dp-flicker)" do
    before { DashboardsController.reset! }

    def flickering? = page.evaluate_script("document.querySelector('#temp-readout').classList.contains('dp-readout--flicker')")

    it "does not flicker when the page loads, nor on a plain Turbo visit" do
      visit "/dashboard"
      sleep 0.3
      expect(flickering?).to be(false)
      page.execute_script("Turbo.visit('/somewhere-else')")
      expect(page).to have_current_path("/somewhere-else")
      page.execute_script("Turbo.visit('/dashboard')")
      expect(page).to have_css("#temp-readout")
      sleep 0.2
      expect(flickering?).to be(false)
    end

    it "flickers once when a Turbo Stream replaces it with a new value, then stops" do
      visit "/dashboard"
      click_button "Refresh readings"
      wait_until("the new value") { page.evaluate_script("document.querySelector('#temp-readout .dp-readout__number').textContent.trim()") == "19.7" }
      wait_until("the flicker class") { flickering? }
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#temp-readout')).animationName")).to eq("dp-flicker")
      wait_until("the flicker to end") { !flickering? }
    end

    it "keeps the text and its contrast during the flicker (only an outline blinks)" do
      visit "/dashboard"
      click_button "Refresh readings"
      wait_until("the flicker class") { flickering? }
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#temp-readout .dp-readout__number')).opacity")).to eq("1")
      expect(axe_violations).to be_empty, axe_report(axe_violations)
    end

    it "is neutralised by prefers-reduced-motion" do
      visit "/dashboard"
      reduce_motion
      click_button "Refresh readings"
      wait_until("the flicker class") { flickering? }
      expect(seconds(style_of("#temp-readout", "animationDuration"))).to be <= 0.001
      expect(style_of("#temp-readout", "animationIterationCount")).to eq("1")
    end
  end
end
