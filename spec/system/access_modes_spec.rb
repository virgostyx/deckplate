require "spec_helper"

# Low-vision and touch modes: browser zoom, forced colours (Windows high contrast), coarse pointers.
RSpec.describe "Access modes", type: :system, js: true do
  before { driven_by :dp_cuprite }

  # Fixed-geometry decorative demo: a 10u elbow is 320 px wide at the root size, wider than a 320-640 px screen once doubled.
  # A percentage max-inline-size was tried and rejected: it collapses elbows inside auto grid tracks (Panel, Frame).
  REFLOW_EXCEPTIONS = %w[elbow/variants].freeze

  describe "200% zoom (WCAG 1.4.4 / 1.4.10)" do
    # 200% zoom on a 1280 px window = 640 CSS px wide with the root font doubled; 400% on 1280 = 320 CSS px
    { "200%" => [ 640, 200 ], "400% (reflow)" => [ 320, 400 ] }.each do |name, (width, percent)|
      OverflowHelper::ALL_PREVIEWS.call.reject { (OverflowHelper::DESKTOP_ONLY + REFLOW_EXCEPTIONS).include?(_1) }.each do |preview|
        it "#{preview} reflows at #{name}" do
          page.current_window.resize_to(width, 900)
          visit "/rails/view_components/#{preview}"
          expect(page).to have_css("html[data-dp-theme]")
          page.execute_script("document.documentElement.style.fontSize = '#{percent}%'") if percent == 200
          expect(overflowing_elements).to eq([])
        end
      end
    end
  end

  describe "forced colours" do
    BORDERED = %w[.dp-button .dp-alert .dp-toast .dp-input .dp-select .dp-textarea .dp-condition-banner].freeze

    %w[button/default alert/default toast/default text_input/default select/default textarea/default condition_banner/default].each do |preview|
      it "#{preview}: boxes keep a visible border or outline" do
        emulate_media(forced_colors: "active")
        visit "/rails/view_components/#{preview}"
        expect(page.evaluate_script("matchMedia('(forced-colors: active)').matches")).to be(true)
        missing = page.evaluate_script(<<~JS)
          Array.from(document.querySelectorAll(#{BORDERED.join(", ").to_json})).filter(function (el) {
            var s = getComputedStyle(el)
            var border = parseFloat(s.borderTopWidth) > 0 && s.borderTopStyle !== "none"
            var outline = parseFloat(s.outlineWidth) > 0 && s.outlineStyle !== "none"
            return !(border || outline)
          }).map(function (el) { return el.className })
        JS
        expect(missing).to eq([])
      end
    end

    it "keeps the on/off state of a switch visible without colour (the thumb moves and carries a tick when on)" do
      emulate_media(forced_colors: "active")
      visit "/rails/view_components/toggle/default"
      read = lambda do |checked|
        page.execute_script("document.querySelector('.dp-toggle__input').checked = #{checked}")
        sleep 0.4 # the thumb slides (transition)
        page.evaluate_script("(function(){ var t = document.querySelector('.dp-toggle__thumb'); return [ Math.round(t.getBoundingClientRect().left - t.parentElement.getBoundingClientRect().left), getComputedStyle(t, '::after').content ] })()")
      end
      on = read.call(true)
      off = read.call(false)
      expect(on[0]).to be > off[0]
      expect(on[1]).not_to eq(off[1])
    end
  end

  describe "coarse pointers (touch)" do
    TOUCH_TARGETS = ".dp-button, .dp-input, .dp-select, .dp-textarea, .dp-toggle, .dp-choice, [role='tab'], .dp-pagination__link".freeze

    before do
      pg = page.driver.browser.page
      pg.command("Emulation.setEmitTouchEventsForMouse", enabled: true, configuration: "mobile")
      pg.command("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 1)
    end

    %w[button/default text_input/default select/default toggle/default checkbox/default tabs/default pagination/default keypad/default].each do |preview|
      it "#{preview}: every control is at least 44px tall" do
        visit "/rails/view_components/#{preview}"
        expect(page.evaluate_script("matchMedia('(pointer: coarse)').matches")).to be(true)
        small = page.evaluate_script(<<~JS)
          Array.from(document.querySelectorAll(#{TOUCH_TARGETS.to_json})).filter(function (el) {
            return el.type !== "hidden" && el.getBoundingClientRect().width > 0 && el.getBoundingClientRect().height < 43.5
          }).map(function (el) { return el.className + " " + Math.round(el.getBoundingClientRect().height) })
        JS
        expect(small).to eq([])
      end
    end
  end
end
