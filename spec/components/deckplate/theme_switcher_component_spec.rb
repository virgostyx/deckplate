require "spec_helper"

RSpec.describe Deckplate::ThemeSwitcherComponent, type: :component do
  after { Deckplate.reset_configuration! }

  def group = page.find("[role='group']", visible: :all)
  def buttons = page.all("button.dp-button", visible: :all)

  it "renders a named group with one toggle button per enabled theme, labelled with the theme's name" do
    render_inline(described_class.new)
    expect(group["aria-label"]).to eq("Theme")
    expect(buttons.map { _1.text(:all).strip }).to eq([ "Classic", "Azure", "Nocturne", "Daylight", "Crimson", "Verdant", "High contrast" ])
  end

  it "uses aria-pressed for the current theme (the default, or the one in the dp_theme cookie)" do
    render_inline(described_class.new)
    expect(buttons.to_h { [ _1.text(:all).strip, _1["aria-pressed"] ] }).to eq("Classic" => "true", "Azure" => "false", "Nocturne" => "false", "Daylight" => "false", "Crimson" => "false", "Verdant" => "false", "High contrast" => "false")
    vc_test_request.cookies["dp_theme"] = "daylight"
    render_inline(described_class.new)
    expect(buttons.find { _1["aria-pressed"] == "true" }.text(:all).strip).to eq("Daylight")
  end

  it "shows the current theme with a mark that is not a colour (a bar under the label, defined in the button CSS)" do
    render_inline(described_class.new)
    expect(File.read(Deckplate::Engine.root.join("app/assets/stylesheets/deckplate/components/controls/button.css"))).to match(/\[aria-pressed="true"\]/)
  end

  it "wires the controller: the allowed themes, the cookie name and one action per button" do
    render_inline(described_class.new)
    expect(group["data-controller"]).to eq("dp-theme")
    expect(JSON.parse(group["data-dp-theme-themes-value"])).to eq(%w[classic azure nocturne daylight crimson verdant high-contrast])
    expect(group["data-dp-theme-cookie-value"]).to eq("dp_theme")
    expect(buttons.map { _1["data-action"] }.uniq).to eq([ "dp-theme#select" ])
    expect(buttons.map { _1["data-dp-theme-name-param"] }).to eq(%w[classic azure nocturne daylight crimson verdant high-contrast])
  end

  it "offers only the themes the host enabled, including custom ones" do
    Deckplate.configure { |c| c.themes = %i[classic my-brand]; c.default_theme = :classic }
    render_inline(described_class.new)
    expect(buttons.map { _1.text(:all).strip }).to eq([ "Classic", "My brand" ])
  end

  it "translates the label and the theme names" do
    I18n.with_locale(:fr) { render_inline(described_class.new) }
    expect(group["aria-label"]).to eq("Thème")
    expect(buttons.map { _1.text(:all).strip }.first(2)).to eq(%w[Classique Azur])
  end

  it "takes a custom label and passes html options through" do
    render_inline(described_class.new(label: "Appearance", class: "x", id: "ts"))
    expect(page).to have_css("#ts.dp-theme-switcher.x[aria-label='Appearance']", visible: :all)
  end

  it "is render-pure" do
    expect(render_inline(described_class.new).to_html).to eq(render_inline(described_class.new).to_html)
  end
end
