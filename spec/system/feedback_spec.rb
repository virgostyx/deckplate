require "spec_helper"

RSpec.describe "Feedback components in the browser", type: :system, js: true do
  before { driven_by :dp_cuprite }

  def toasts = page.all("#dp-toasts .dp-toast", wait: 0).map { _1.text.squish }
  def reduce_motion = page.driver.browser.page.command("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])

  describe "Toasts through Turbo Streams" do
    before do
      visit "/toasts"
      page.execute_script("window.__sameDocument = true")
    end

    it "has a polite live region ready before any toast exists (that is what makes additions announced)" do
      region = page.find("#dp-toasts", visible: :all)
      expect(region["aria-live"]).to eq("polite")
      expect(region["aria-relevant"]).to eq("additions")
      expect(region[:role]).to eq("region")
      expect(toasts).to eq([])
    end

    it "appends the toast from the stream response, with the right role, without a page load" do
      click_button "Sticky toast"
      expect(page).to have_css("#dp-toasts .dp-toast[role='status']", text: "Stays")
      expect(page.evaluate_script("window.__sameDocument")).to be(true)
      expect(page.evaluate_script("document.querySelector('#dp-toasts .dp-toast').parentElement.id")).to eq("dp-toasts")
    end

    it "dismisses itself after its duration, and leaves no timer behind" do
      click_button "Success toast"
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Saved")
      expect(page).to have_no_css("#dp-toasts .dp-toast", text: "Saved", wait: 4)
    end

    it "keeps an error until the user dismisses it, as an alert" do
      click_button "Error toast"
      expect(page).to have_css("#dp-toasts .dp-toast[role='alert']", text: "It failed")
      sleep 1.2
      expect(toasts.join).to include("It failed")
      find("#dp-toasts .dp-toast__close").click
      expect(page).to have_no_css("#dp-toasts .dp-toast")
    end

    it "pauses the countdown while the pointer is over the toast, and resumes when it leaves" do
      click_button "Slow toast"
      toast = find("#dp-toasts .dp-toast", text: "Slow info")
      sleep 0.4
      toast.hover
      sleep 1.6 # longer than the 1.5 s duration: it would be gone if the timer ran
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Slow info")
      find("h1").hover
      expect(page).to have_no_css("#dp-toasts .dp-toast", text: "Slow info", wait: 4)
    end

    it "pauses while a control inside the toast has the keyboard focus" do
      click_button "Slow toast"
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Slow info")
      sleep 0.3
      focus("#dp-toasts .dp-toast__close")
      sleep 1.8
      expect(toasts.join).to include("Slow info")
      page.execute_script("document.activeElement.blur()")
      expect(page).to have_no_css("#dp-toasts .dp-toast", text: "Slow info", wait: 4)
    end

    it "caps the stack at the container's limit, oldest first" do
      %w[One Two Three Four Five].each_with_index do |name, i|
        page.execute_script(<<~JS)
          fetch("/toasts?kind=info&duration=0&message=#{name}", { method: "POST", headers: { "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content } })
            .then(r => r.text()).then(html => Turbo.renderStreamMessage(html))
        JS
        expect(page).to have_css("#dp-toasts .dp-toast", text: name)
      end
      expect(toasts.map { _1.sub(/\A.*?:\s*/, "") }).to eq(%w[Three Four Five])
    end

    it "gives every toast a translated, focusable close button that removes only that toast" do
      click_button "Sticky toast"
      click_button "Error toast"
      expect(page).to have_css("#dp-toasts .dp-toast", count: 2)
      find("#dp-toasts .dp-toast", text: "Stays").find(".dp-toast__close").click
      expect(toasts.join).to include("It failed")
      expect(toasts.join).not_to include("Stays")
    end

    it "is accessible" do
      click_button "Error toast"
      expect(page).to have_css("#dp-toasts .dp-toast")
      expect(axe_violations).to be_empty, axe_report(axe_violations)
    end
  end

  describe "Toasts and a Turbo morph refresh" do
    def morph = (page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })"); sleep 0.8)

    it "keeps them when the container is permanent" do
      visit "/toasts?permanent=1"
      click_button "Sticky toast"
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Stays")
      morph
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Stays")
    end

    it "loses them otherwise (the server markup of the container is empty): documented in the guide" do
      visit "/toasts"
      click_button "Sticky toast"
      expect(page).to have_css("#dp-toasts .dp-toast", text: "Stays")
      morph
      expect(page).to have_no_css("#dp-toasts .dp-toast")
    end
  end

  describe "Alert (dp-dismiss)" do
    before { visit "/rails/view_components/alert/kinds" }

    it "is removed by its close button, and the focus moves on instead of being lost" do
      expect(page).to have_css("#long-alert")
      find("#long-alert .dp-alert__close").click
      expect(page).to have_no_css("#long-alert")
      wait_until("focus on the next focusable element") { active_text =~ /next focusable/i }
    end

    it "removes only the dismissed alert" do
      before = page.all(".dp-alert").size
      find("#long-alert .dp-alert__close").click
      expect(page.all(".dp-alert").size).to eq(before - 1)
    end

    it "can be dismissed with the keyboard" do
      focus("#long-alert .dp-alert__close")
      press(:Enter)
      expect(page).to have_no_css("#long-alert")
    end
  end

  describe "ConditionBanner" do
    before { visit "/rails/view_components/condition_banner/conditions" }

    it "has a static hazard marker for critical, whatever the motion preference" do
      reduce_motion
      bg = page.evaluate_script("getComputedStyle(document.querySelector('.dp-condition-banner--critical .dp-condition-banner__marker')).backgroundImage")
      expect(bg).to include("repeating-linear-gradient")
    end

    it "pulses only the critical banner, and not at all under prefers-reduced-motion" do
      names = page.evaluate_script("[...document.querySelectorAll('.dp-condition-banner')].map(b => getComputedStyle(b).animationName)")
      expect(names.first(2)).to eq(%w[none none]) # normal, caution
      expect(names[2]).to eq("dp-pulse")
      reduce_motion
      iteration = page.evaluate_script("getComputedStyle(document.querySelector('.dp-condition-banner--critical')).animationIterationCount")
      expect(iteration).to eq("1")
      expect(page.evaluate_script("parseFloat(getComputedStyle(document.querySelector('.dp-condition-banner--critical')).animationDuration) * 1000")).to be <= 1
    end

    it "uses the crimson theme for the critical banner only" do
      expect(page.evaluate_script("document.querySelector('.dp-condition-banner--critical').closest('[data-dp-theme]').dataset.dpTheme")).to eq("crimson")
      expect(page.evaluate_script("document.querySelector('.dp-condition-banner--normal').closest('[data-dp-theme]').dataset.dpTheme")).to eq("classic")
    end
  end

  describe "Spinner and Skeleton under prefers-reduced-motion" do
    it "stop animating" do
      visit "/rails/view_components/spinner/default"
      reduce_motion
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.dp-spinner__bars > span')).animationIterationCount")).to eq("1")
      visit "/rails/view_components/skeleton/default"
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.dp-skeleton__shape')).animationIterationCount")).to eq("1")
    end
  end
end
