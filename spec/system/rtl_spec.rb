require "spec_helper"

# Right-to-left support (ADR 0017). The direction is set by the host on <html>; the preview layout reads ?dir=rtl.
RSpec.describe "Right-to-left", type: :system, js: true do
  before { driven_by :dp_cuprite }

  # Which physical corner of the box carries the outer radius: "top-left", "top-right", "bottom-left" or "bottom-right"
  def rounded_corner(selector)
    page.evaluate_script(<<~JS)
      (function () {
        var s = getComputedStyle(document.querySelector(#{selector.to_json}))
        var corners = { "top-left": s.borderTopLeftRadius, "top-right": s.borderTopRightRadius, "bottom-left": s.borderBottomLeftRadius, "bottom-right": s.borderBottomRightRadius }
        return Object.keys(corners).filter(function (k) { return parseFloat(corners[k]) > 0 })[0]
      })()
    JS
  end

  describe "Elbow corners" do
    LOGICAL = { "top_start" => %w[top-left top-right], "top_end" => %w[top-right top-left],
                "bottom_start" => %w[bottom-left bottom-right], "bottom_end" => %w[bottom-right bottom-left] }.freeze

    LOGICAL.each do |corner, (ltr, rtl)|
      it "#{corner} is the #{ltr} shape in LTR and the #{rtl} shape in RTL" do
        visit "/rails/view_components/elbow/logical"
        expect(rounded_corner("#logical .dp-elbow--#{corner.tr('_', '-')}")).to eq(ltr)
        visit "/rails/view_components/elbow/logical?dir=rtl"
        expect(rounded_corner("#logical .dp-elbow--#{corner.tr('_', '-')}")).to eq(rtl)
      end
    end

    %w[top-left top-right bottom-left bottom-right].each do |corner|
      it "the physical #{corner} corner never mirrors" do
        visit "/rails/view_components/elbow/logical?dir=rtl"
        expect(rounded_corner("#physical .dp-elbow--#{corner}")).to eq(corner)
      end
    end

    it "mirrors the label side with the corner" do
      visit "/rails/view_components/elbow/labels?dir=rtl"
      expect(page).to have_css(".dp-elbow__label", count: 4)
    end
  end

  describe "directional icons" do
    def transform(selector) = page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).transform")

    it "chevrons mirror in RTL and stay as drawn in LTR" do
      visit "/rails/view_components/pagination/default"
      expect(transform(".dp-icon--directional")).to eq("none")
      visit "/rails/view_components/pagination/default?dir=rtl"
      expect(transform(".dp-icon--directional")).to eq("matrix(-1, 0, 0, 1, 0, 0)")
    end
  end

  describe "slider fill" do
    # The browser does not expose the computed style of the native track, so the rules are read from the stylesheet (a visual baseline covers the rendering)
    def track_rules = page.evaluate_script(<<~JS)
      Array.from(document.styleSheets).flatMap(function (sheet) { return Array.from(sheet.cssRules) })
        .flatMap(function (rule) { return rule.cssRules ? Array.from(rule.cssRules) : [ rule ] })
        .filter(function (rule) { return rule.selectorText && rule.selectorText.indexOf("slider-runnable-track") >= 0 })
        .map(function (rule) { return rule.cssText })
    JS

    it "fills from the side where the value starts: to right by default, to left in RTL" do
      visit "/rails/view_components/slider/default"
      rules = track_rules
      expect(rules.grep(/:dir\(rtl\)/).join).to include("to left")
      expect(rules.grep_v(/:dir\(rtl\)/).join).to include("to right")
    end
  end

  describe "popovers (tooltip and menu)" do
    # The popover is aligned on the side where the text starts: left edges in LTR, right edges in RTL
    def edge(selector, dir) = page.evaluate_script("document.querySelector(#{selector.to_json}).getBoundingClientRect().#{dir == 'rtl' ? 'right' : 'left'}")

    %w[ltr rtl].each do |dir|
      it "a tooltip opens under its host, aligned on the start side, in #{dir}" do
        visit "/rails/view_components/tooltip/default?dir=#{dir}"
        find("#tip-shields button, #tip-shields ~ * button, .dp-tooltip button", match: :first).hover
        page.execute_script("document.querySelector('.dp-tooltip button').focus()")
        wait_until("the tooltip") { page.evaluate_script("document.querySelector('.dp-tooltip__bubble').matches(':popover-open')") }
        expect(edge(".dp-tooltip__bubble", dir)).to be_within(2).of(edge(".dp-tooltip", dir))
      end

      it "a menu opens under its trigger, aligned on the start side, in #{dir}" do
        visit "/rails/view_components/menu/default?dir=#{dir}"
        find(".dp-menu button", match: :first).click
        wait_until("the menu") { page.evaluate_script("document.querySelector('.dp-menu__list').matches(':popover-open')") }
        expect(edge(".dp-menu__list", dir)).to be_within(2).of(edge(".dp-menu button", dir))
      end
    end
  end

  describe "data values" do
    it "keeps a value and its unit readable in RTL: each is isolated as left-to-right text" do
      visit "/rails/view_components/readout/default?dir=rtl"
      %w[.dp-readout__number .dp-readout__unit].each do |selector|
        style = page.evaluate_script("(function(){ var s = getComputedStyle(document.querySelector(#{selector.to_json})); return [s.direction, s.unicodeBidi] })()")
        expect(style).to eq(%w[ltr isolate])
      end
    end

    it "keeps a clock left-to-right in RTL" do
      visit "/rails/view_components/clock/default?dir=rtl"
      style = page.evaluate_script("(function(){ var s = getComputedStyle(document.querySelector('.dp-clock')); return [s.direction, s.unicodeBidi] })()")
      expect(style).to eq(%w[ltr isolate])
    end
  end

  describe "Frame entrance animation (animate: true)" do
    def animation_names = page.evaluate_script("(function(){ var n = function (sel) { return getComputedStyle(document.querySelector(sel)).animationName }; return [ n('.dp-frame__header'), n('.dp-frame__sidebar') ] })()")

    it "reveals and slides in from the side where the layout starts" do
      page.current_window.resize_to(1280, 900)
      visit "/rails/view_components/frame/animated"
      expect(animation_names).to eq(%w[dp-frame-reveal dp-frame-slide])
      visit "/rails/view_components/frame/animated?dir=rtl"
      expect(animation_names).to eq(%w[dp-frame-reveal-rtl dp-frame-slide-rtl])
    end
  end

  describe "Timeline" do
    %w[ltr rtl].each do |dir|
      it "keeps the time of an event on the start side of its content, in #{dir}" do
        visit "/rails/view_components/timeline/default?dir=#{dir}"
        edge = dir == "rtl" ? "right" : "left"
        # the position of the text itself (a block's own box spans the whole width whatever its text does)
        text_edge = ->(selector) { page.evaluate_script("(function(){ var r = document.createRange(); r.selectNodeContents(document.querySelector(#{selector.to_json})); return r.getBoundingClientRect().#{edge} })()") }
        expect(text_edge.call(".dp-timeline__time")).to be_within(2).of(text_edge.call(".dp-timeline__title"))
      end
    end
  end

  describe "Keypad" do
    # A numeric keypad keeps its layout in any page direction (like a phone or a cash machine): 1 2 3 from the left
    def lefts = page.evaluate_script("(function(){ var l = function (sel) { return document.querySelector(sel).getBoundingClientRect().left }; return [ l(\"[data-dp-keypad-digit-param='1']\"), l(\"[data-dp-keypad-digit-param='2']\"), l(\"[data-dp-keypad-digit-param='3']\") ] })()")

    %w[ltr rtl].each do |dir|
      it "puts 1, 2, 3 from left to right in #{dir}" do
        visit "/rails/view_components/keypad/default?dir=#{dir}"
        one, two, three = lefts
        expect(one).to be < two
        expect(two).to be < three
      end
    end

    it "keeps the digits of the field left to right in RTL" do
      visit "/rails/view_components/keypad/default?dir=rtl"
      expect(page.evaluate_script("getComputedStyle(document.querySelector('.dp-keypad__input')).direction")).to eq("ltr")
    end
  end

  describe "Frame drawer (narrow screens)" do
    %w[ltr rtl].each do |dir|
      it "opens from the side where the layout starts, in #{dir}" do
        page.current_window.resize_to(375, 800)
        visit "/rails/view_components/frame/classic?dir=#{dir}"
        find(".dp-frame__menu-button, button[popovertarget]", match: :first).click
        wait_until("the drawer") { page.evaluate_script("document.querySelector('.dp-frame__sidebar').matches(':popover-open')") }
        rect = page.evaluate_script("(function(){ var r = document.querySelector('.dp-frame__sidebar').getBoundingClientRect(); return [ r.left, r.right, window.innerWidth ] })()")
        left, right, width = rect
        dir == "rtl" ? expect(right).to(be_within(1).of(width)) : expect(left).to(be_within(1).of(0))
      end
    end
  end
end
