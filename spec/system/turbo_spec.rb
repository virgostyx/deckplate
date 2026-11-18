require "spec_helper"

# Turbo compatibility (PLAN Definition of Done, point 8): navigation + back button (cache restore) and morph refreshes.
RSpec.describe "Turbo compatibility", type: :system, js: true do
  before { driven_by :dp_cuprite }

  def turbo_visit(path) = page.execute_script("Turbo.visit(#{path.to_json})")
  def morph_refresh = page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
  def wait_for_morph = sleep(0.5)

  def away_and_back(preview)
    turbo_visit("/somewhere-else")
    expect(page).to have_current_path("/somewhere-else")
    page.go_back
    expect(page).to have_current_path(%r{#{Regexp.escape(preview)}})
    expect(page).to have_css("[data-controller]")
  end

  describe "navigation and back button" do
    it "tabs work after returning from the Turbo cache (no stale or duplicated controller)" do
      visit "/rails/view_components/tabs/default"
      away_and_back("/tabs/default")
      find("#crew-tab").click
      expect(attribute("#crew-tab", "aria-selected")).to eq("true")
      expect(page.evaluate_script("document.querySelectorAll('[role=tab][aria-selected=true]').length")).to eq(1)
      focus("#crew-tab")
      press(:Right)
      wait_until("one step to the next tab (a duplicated controller would move twice)") { active_id == "cargo-tab" }
    end

    it "a menu left open is closed when Turbo caches the page" do
      visit "/rails/view_components/menu/default"
      find("[aria-haspopup='menu']").click
      expect(page).to have_css("#ship-menu:popover-open")
      away_and_back("/menu/default")
      expect(page).not_to have_css("#ship-menu:popover-open")
      find("[aria-haspopup='menu']").click
      expect(page).to have_css("#ship-menu:popover-open")
    end

    it "a modal left open is closed and the scroll lock released when Turbo caches the page" do
      visit "/rails/view_components/modal/default"
      find("button", text: /open dialog/i).click
      expect(page).to have_css("dialog[open]")
      away_and_back("/modal/default")
      expect(page).not_to have_css("dialog[open]")
      expect(page.evaluate_script("document.documentElement.classList.contains('dp-scroll-lock')")).to be(false)
      find("button", text: /open dialog/i).click
      expect(page).to have_css("dialog[open]")
    end

    it "the slider readout still follows the keyboard after a back navigation" do
      visit "/rails/view_components/slider/default"
      away_and_back("/slider/default")
      expect(page).to have_css("input[type='range']") # Turbo restores the page from its cache asynchronously: wait for it before focusing
      focus("input[type='range']")
      press(:Right)
      expect(page).to have_css("output", text: "73%")
    end
  end

  describe "inside a Turbo Frame" do
    it "renders and drives components loaded into a frame" do
      visit "/rails/view_components/tabs/default"
      page.execute_script(<<~JS)
        const frame = document.createElement("turbo-frame")
        frame.id = "demo"
        frame.innerHTML = '<div class="dp-root">' + document.querySelector(".dp-tabs").outerHTML.replaceAll('id="', 'id="f-') + '</div>'
        document.body.appendChild(frame)
      JS
      expect(page).to have_css("turbo-frame#demo .dp-tabs")
      within("turbo-frame#demo") do
        find("#f-crew-tab").click
        expect(page).to have_css("#f-crew-tab[aria-selected='true']")
      end
    end
  end

  describe "morph refresh (turbo_refreshes_with method: :morph)" do
    it "keeps the selected tab" do
      visit "/rails/view_components/tabs/default"
      find("#cargo-tab").click
      morph_refresh
      wait_for_morph
      expect(attribute("#cargo-tab", "aria-selected")).to eq("true")
      expect(page.evaluate_script("[...document.querySelectorAll('[role=tabpanel]')].filter(p => !p.hidden).map(p => p.id)")).to eq([ "cargo-panel" ])
    end

    it "keeps an open menu open with its items focusable" do
      visit "/rails/view_components/menu/default"
      find("[aria-haspopup='menu']").click
      expect(page).to have_css("#ship-menu:popover-open")
      morph_refresh
      wait_for_morph
      expect(page).to have_css("#ship-menu:popover-open")
      expect(attribute("[aria-haspopup='menu']", "aria-expanded")).to eq("true")
    end

    it "keeps an open modal open" do
      visit "/rails/view_components/modal/default"
      find("button", text: /open dialog/i).click
      expect(page).to have_css("dialog[open]")
      morph_refresh
      wait_for_morph
      expect(page).to have_css("dialog[open]")
      expect(page.evaluate_script("document.querySelector('dialog').matches(':modal')")).to be(true)
    end

    it "keeps the slider value, readout and fill" do
      visit "/rails/view_components/slider/default"
      focus("input[type='range']")
      press(:Right, :Right, :Right)
      expect(page).to have_css("output", text: "75%")
      morph_refresh
      wait_for_morph
      expect(page.evaluate_script("document.querySelector('input[type=range]').value")).to eq("75")
      expect(page).to have_css("output", text: "75%")
      expect(page.evaluate_script("document.querySelector('.dp-slider').style.getPropertyValue('--dp-pct')")).to eq("75")
    end
  end
end
