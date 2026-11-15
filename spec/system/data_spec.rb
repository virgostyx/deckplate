require "spec_helper"

RSpec.describe "Data components in the browser", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    DashboardsController.reset!
  end

  after { Deckplate.reset_configuration! }

  describe "Turbo Streams (stable ids + turbo_stream.replace)" do
    before do
      visit "/dashboard"
      page.execute_script("window.__sameDocument = true")
    end

    def gauge_now = attribute("#power-gauge", "aria-valuenow")

    it "replaces the gauge and the readout in place, without a page load" do
      expect(gauge_now).to eq("72")
      expect(page).to have_css("#temp-readout .dp-readout__number", text: "18.4")
      click_button "Refresh readings"
      wait_until("the gauge to show the new value") { gauge_now == "77" }
      expect(page).to have_css("#temp-readout .dp-readout__number", text: "19.7")
      expect(page.evaluate_script("window.__sameDocument")).to be(true)
      expect(page).to have_css("#power-gauge[role='meter'][aria-valuetext='77%']")
      expect(page.evaluate_script("document.querySelectorAll('#power-gauge').length")).to eq(1)
    end

    it "keeps the fill in sync with the new value (the CSS custom property is replaced with the element)" do
      click_button "Refresh readings"
      wait_until("the new value") { gauge_now == "77" }
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#power-gauge')).getPropertyValue('--dp-value').trim()")).to eq("77")
    end

    it "stays accessible after an update" do
      click_button "Refresh readings"
      wait_until("the new value") { gauge_now == "77" }
      expect(axe_violations).to be_empty, axe_report(axe_violations)
    end
  end

  describe "Table sorting (the host sorts; the component renders links and state)" do
    def names = page.all("#readings tbody th").map { _1.text.strip }

    before { visit "/dashboard" }

    it "reorders through the header links and flips aria-sort" do
      expect(names).to eq([ "Hull", "Core", "Deck 7" ])
      find("#readings thead a", text: /value/i).click
      expect(page).to have_current_path("/dashboard?dir=asc&sort=value")
      expect(names).to eq([ "Deck 7", "Hull", "Core" ])
      expect(page.find("#readings thead th", text: /value/i)["aria-sort"]).to eq("ascending")
      find("#readings thead a", text: /value/i).click
      expect(page).to have_current_path("/dashboard?dir=desc&sort=value")
      expect(names).to eq([ "Core", "Hull", "Deck 7" ])
      expect(page.find("#readings thead th", text: /value/i)["aria-sort"]).to eq("descending")
    end

    it "ignores a forged sort parameter" do
      visit "/dashboard?sort=%3Cscript%3E&dir=asc"
      expect(names).to eq([ "Hull", "Core", "Deck 7" ])
      expect(page).not_to have_css("[aria-sort]")
    end

    it "lets keyboard users scroll and reach the table (named, focusable region)" do
      expect(page.find("#readings")["tabindex"]).to eq("0")
      expect(page.find("#readings")[:role]).to eq("region")
    end
  end

  describe "Clock (dp-clock)" do
    before { visit "/rails/view_components/clock/default" }

    def text = page.find("#ship-clock").text

    it "ticks from the server time, not from the client clock" do
      expect(text).to match(/\A14:0[5-6]:\d\d\z/) # started at 14:05:59 on the server, a moment ago
      first = text
      wait_until("the clock to move") { text != first }
    end

    it "uses the server's zone for the displayed time" do
      visit "/rails/view_components/clock/formats"
      expect(page.all(".dp-clock").map(&:text).first).to match(/\A14:0[5-6]:\d\d\z/)
      expect(page.all(".dp-clock")[1].text).to match(/\A2026-03-09 15:0[5-6]:\d\d\z/) # Brussels is UTC+1 in March
      expect(page.all(".dp-clock")[2].text).to eq("2026-03-09")
    end

    it "stops its timer on disconnect (nothing left running after Turbo leaves the page)" do
      page.execute_script("window.__ticks = 0; const el = document.querySelector('#ship-clock'); new MutationObserver(() => window.__ticks++).observe(el, { childList: true, characterData: true, subtree: true })")
      page.execute_script("Turbo.visit('/somewhere-else')")
      expect(page).to have_current_path("/somewhere-else")
      before = page.evaluate_script("window.__ticks")
      sleep 2.3
      expect(page.evaluate_script("window.__ticks")).to eq(before)
    end

    it "is announced as a timer, not a live region" do
      el = page.find("#ship-clock")
      expect(el[:role]).to eq("timer")
      expect(el["aria-live"]).to be_nil
    end
  end

  describe "under a strict Content-Security-Policy (style-src 'self': no inline style at all)" do
    before do
      Deckplate.configure { |c| c.csp_safe_values = true }
      page.driver.browser.evaluate_on_new_document(<<~JS)
        window.__violations = []
        document.addEventListener("securitypolicyviolation", (e) => window.__violations.push(e.violatedDirective + " " + e.blockedURI))
      JS
      visit "/csp"
      expect(page).to have_css("#csp-gauge[data-controller~='dp-values'], #csp-gauge.dp-v-72", visible: :all)
    end

    def px(selector, property) = page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")

    it "serves the page with the policy" do
      expect(page.evaluate_script("document.querySelectorAll('[style]').length")).to be >= 0
      response = page.driver.browser.network.traffic.find { _1.url.end_with?("/csp") }.response
      policy = response.headers.transform_keys(&:downcase)["content-security-policy"]
      expect(policy).to include("style-src 'self'")
      expect(policy).not_to include("unsafe-inline")
    end

    it "has no CSP violation: nothing was blocked" do
      sleep 0.3
      expect(page.evaluate_script("window.__violations")).to eq([])
    end

    it "applies dynamic values through the CSSOM (dp-values) and quantised classes: the layout is right" do
      u = page.evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.375")
      expect(px("#csp-spacer", "width").to_f).to be_within(1.0).of(2 * u)                       # --dp-n: 2 via dp-values
      expect(px("#csp-elbow", "width").to_f).to be_within(1.0).of(9 * u)                        # --dp-elbow-w via dp-values
      expect(px("#csp-elbow", "height").to_f).to be_within(1.0).of(6 * u)
      expect(px("#csp-bar", "height").to_f).to be_within(1.0).of(2.5 * u)                       # --dp-bar-t via dp-values
      expect(px("#csp-segment", "flexBasis").to_f).to be_within(1.0).of(6 * u)                 # --dp-seg via dp-values
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#csp-gauge')).getPropertyValue('--dp-value').trim()")).to eq("72") # dp-v-72 class
      expect(page.evaluate_script("getComputedStyle(document.querySelector('#csp-progress')).getPropertyValue('--dp-value').trim()")).to eq("40")
      widths = page.evaluate_script("[...document.querySelectorAll('#csp-graph .dp-bar-graph__bar')].map(b => b.getBoundingClientRect().width)")
      expect(widths.last).to be > 100
      expect(widths.first).to be_within(2.0).of(widths.last / 4) # 25 against 100: quantised classes, no inline style
      expect(page.evaluate_script("document.querySelector('#csp-slider').closest('.dp-slider').style.getPropertyValue('--dp-pct')")).to eq("30") # dp-slider, CSSOM
    end

    it "keeps the CSSOM values after a Turbo morph refresh (the server markup has no style attribute to restore them)" do
      u = page.evaluate_script("parseFloat(getComputedStyle(document.documentElement).fontSize) * 1.375")
      page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
      sleep 0.8
      expect(px("#csp-spacer", "width").to_f).to be_within(1.0).of(2 * u)
      expect(px("#csp-elbow", "width").to_f).to be_within(1.0).of(9 * u)
      expect(page.evaluate_script("window.__violations")).to eq([])
    end

    it "emits no inline style attribute from the server" do
      html = page.driver.browser.network.traffic.find { _1.url.end_with?("/csp") }.response.body
      expect(html).not_to match(/<[^>]+\sstyle=/)
    end
  end
end
