require "spec_helper"

RSpec.describe "Theme switcher (dp-theme)", type: :system, js: true do
  before { driven_by :dp_cuprite }

  def theme = page.evaluate_script("document.documentElement.dataset.dpTheme")
  def cookie = page.driver.browser.cookies.all["dp_theme"]
  def pressed = page.evaluate_script("[...document.querySelectorAll('.dp-theme-switcher button')].filter(b => b.getAttribute('aria-pressed') === 'true').map(b => b.dataset.dpThemeNameParam)")

  describe "on a preview page" do
    before { visit "/rails/view_components/theme_switcher/default" }

    it "starts on the default theme" do
      expect(theme).to eq("classic")
      expect(pressed).to eq([ "classic" ])
    end

    it "switches the theme at once, updates the pressed state and writes the cookie" do
      click_button "Azure"
      expect(theme).to eq("azure")
      expect(pressed).to eq([ "azure" ])
      expect(cookie.value).to eq("azure")
    end

    it "writes a long-lived, site-wide, Lax cookie" do
      click_button "Daylight"
      expect(cookie.path).to eq("/")
      expect(cookie.same_site.to_s.downcase).to eq("lax")
      expect(cookie.expires - Time.now).to be > 300 * 24 * 3600
    end

    it "actually restyles the page (the canvas colour changes)" do
      before = page.evaluate_script("getComputedStyle(document.body).backgroundColor")
      click_button "Daylight"
      expect(page.evaluate_script("getComputedStyle(document.body).backgroundColor")).not_to eq(before)
    end

    it "ignores a theme that is not in the allowed list (the name comes from the DOM)" do
      page.execute_script(<<~JS)
        const el = document.querySelector("[data-controller~='dp-theme']")
        window.Stimulus.getControllerForElementAndIdentifier(el, "dp-theme").select({ params: { name: '"><script>x' } })
      JS
      expect(theme).to eq("classic")
      expect(cookie).to be_nil
    end

    it "is operable with the keyboard" do
      focus(".dp-theme-switcher button[data-dp-theme-name-param='nocturne']")
      press(:Enter)
      expect(theme).to eq("nocturne")
      expect(pressed).to eq([ "nocturne" ])
    end

    it "is accessible in every theme" do
      Deckplate::Configuration::BUILT_IN_THEMES.each do |name|
        click_button I18n.t("deckplate.theme.names.#{name}")
        expect(axe_violations).to be_empty, "#{name}:\n#{axe_report(axe_violations)}"
      end
    end
  end

  describe "persistence" do
    before do
      visit "/profile/new"
      page.execute_script("window.__sameDocument = true")
    end

    it "keeps the theme across Turbo visits (same document, no flash)" do
      click_button "Nocturne"
      page.execute_script("Turbo.visit('/dashboard')")
      expect(page).to have_current_path("/dashboard")
      expect(page.evaluate_script("window.__sameDocument")).to be(true)
      expect(theme).to eq("nocturne")
    end

    it "is rendered by the server on the first paint after a reload (no flash of the wrong theme)" do
      click_button "Crimson"
      visit "/dashboard"
      html = page.evaluate_async_script("var done = arguments[arguments.length - 1]; fetch(location.href).then(r => r.text()).then(done)")
      expect(html).to match(/<html[^>]*data-dp-theme="crimson"/)
      expect(theme).to eq("crimson")
      expect(pressed).to eq([ "crimson" ])
    end

    it "does not trust a forged cookie: an unknown theme falls back to the default on the server" do
      page.driver.browser.cookies.set(name: "dp_theme", value: "evil\"><script>", domain: "127.0.0.1", path: "/")
      visit "/dashboard"
      expect(theme).to eq("classic")
    end

    it "survives a Turbo morph refresh (the server renders the pressed state from the same cookie)" do
      click_button "Azure"
      page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
      sleep 0.7
      expect(theme).to eq("azure")
      expect(pressed).to eq([ "azure" ])
    end
  end
end
