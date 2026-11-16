require "spec_helper"

# ADR 0012: the stylesheet can be loaded per family. Core + one family must style that family's components, and the family
# must not do anything without it. (The preview layout links the sheets named in ?sheets=core,forms; default: deckplate.css.)
RSpec.describe "Per-family stylesheets in the browser", type: :system, js: true do
  before { driven_by :dp_cuprite }

  # family => [preview, selector, computed property, value when styled, value when unstyled]
  CASES = {
    "core"     => [ "bar/default", ".dp-bar", "display", "flex", "block" ],
    "controls" => [ "button/default", ".dp-button", "textTransform", "uppercase", "none" ],
    "forms"    => [ "text_input/default", ".dp-input", "borderTopLeftRadius", "9999px", "0px" ],
    "data"     => [ "gauge/default", ".dp-gauge", "display", "inline-grid", "block" ],
    "feedback" => [ "alert/default", ".dp-alert", "display", "grid", "block" ]
  }.freeze

  def computed(selector, property) = page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
  def sheets_on_page = page.evaluate_script("[...document.querySelectorAll('link[rel=stylesheet]')].map(l => l.href.match(/(deckplate(?:-(?:core|controls|forms|data|feedback))?)-[0-9a-f]{8}\\.css/)?.[1]).filter(Boolean)")

  CASES.each do |family, (preview, selector, property, styled, unstyled)|
    it "#{family}: core + deckplate-#{family} styles #{selector}" do
      visit "/rails/view_components/#{preview}?sheets=#{[ "core", family ].uniq.join(",")}"
      expect(sheets_on_page).to include("deckplate-core")
      expect(computed(selector, property)).to eq(styled)
    end

    next if family == "core"

    it "#{family}: core alone does not style #{selector} (the rules really live in the family sheet)" do
      visit "/rails/view_components/#{preview}?sheets=core"
      expect(sheets_on_page).to eq([ "deckplate-core" ])
      expect(computed(selector, property)).to eq(unstyled)
    end
  end

  it "the all-in-one deckplate.css still styles every family" do
    CASES.each_value do |preview, selector, property, styled, _|
      visit "/rails/view_components/#{preview}"
      expect(sheets_on_page).to eq([ "deckplate" ])
      expect(computed(selector, property)).to eq(styled)
    end
  end

  it "does not depend on the order in which the sheets are linked (each one starts with the layer prelude)" do
    visit "/rails/view_components/button/default?sheets=controls,core"
    expect(sheets_on_page).to eq(%w[deckplate-controls deckplate-core])
    expect(computed(".dp-button", "textTransform")).to eq("uppercase")
    # the cascade layers keep their order whichever sheet came first: component rules still beat the base layer
    expect(computed(".dp-button", "fontFamily")).to include("Antonio")
  end

  it "ignores an unknown sheet name (it is user input in a URL)" do
    visit "/rails/view_components/button/default?sheets=core,../../etc/passwd,controls"
    expect(sheets_on_page).to eq(%w[deckplate-core deckplate-controls])
  end
end
