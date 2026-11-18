require "spec_helper"

RSpec.describe "Theme contrast (WCAG 2.2 AA)" do
  THEMES = Deckplate::Configuration::BUILT_IN_THEMES.map(&:to_s).freeze
  ROLES = %w[primary secondary tertiary accent muted info success warning danger emergency].freeze
  REQUIRED = (ROLES.flat_map { |r| [ "--dp-#{r}", "--dp-#{r}-ink" ] } +
              %w[canvas surface surface-raised ink ink-muted line focus disabled].map { |n| "--dp-#{n}" }).freeze

  let(:rules) { YAML.load_file(File.join(__dir__, "pairs.yml")) }

  def checks_for(theme)
    vars = CssVars.stop_vars.merge(CssVars.theme_vars(theme))
    res = ->(name) { CssVars.resolve("var(--dp-#{name})", vars) }
    list = rules["pairs"].map { |p| [ p["fg"], p["bg"], p["min"] ] }
    ROLES.each { |r| list << [ "#{r}-ink", r, rules["role_ink_min"] ] }
    rules["roles_as_text"]["roles"].each { |r| list << [ r, "canvas", rules["roles_as_text"]["min"] ] }
    ROLES.each { |r| list << [ r, "canvas", rules["roles_as_ui"]["min"] ] }
    list.uniq.map { |fg, bg, min| [ fg, bg, min, CssVars.contrast(res.(fg), res.(bg)), res.(fg), res.(bg) ] }
  end

  THEMES.each do |theme|
    it "#{theme} defines every required variable" do
      expect(REQUIRED - CssVars.theme_vars(theme).keys).to eq([])
    end

    it "#{theme} passes every contrast pair" do
      failures = checks_for(theme).select { |_, _, min, ratio| ratio < min }
      table = failures.map { |fg, bg, min, ratio, f, b| format("  %-18s on %-16s %5.2f < %.1f   (%s on %s)", fg, bg, ratio, min, f, b) }
      expect(failures).to be_empty, "\n#{theme}: #{failures.size} failing pair(s)\n#{table.join("\n")}\n"
    end
  end

  # Found while reviewing the visual baselines: nocturne once mapped primary and warning to the same stop.
  # Roles that carry different meaning must not resolve to the same colour, except where a theme documents it.
  SAME_COLOUR_ALLOWED = { "crimson" => [ %w[danger emergency] ] }.freeze

  THEMES.each do |theme|
    it "#{theme} gives distinct colours to distinct roles" do
      vars = CssVars.stop_vars.merge(CssVars.theme_vars(theme))
      colours = ROLES.to_h { |r| [ r, CssVars.resolve("var(--dp-#{r})", vars) ] }
      clashes = colours.group_by { |_, hex| hex }.values.select { _1.size > 1 }.map { |g| g.map(&:first).sort }
      expect(clashes - SAME_COLOUR_ALLOWED.fetch(theme, [])).to eq([])
    end
  end

  it "keeps every palette stop's ink readable on the stop" do
    bad = CssVars.palette.select { |_, s| CssVars.contrast(s["hex"], s["ink"]) < rules["stop_ink_min"] }.keys
    expect(bad).to eq([])
  end

  # The unfilled part of a gauge or slider is drawn with --dp-track, which falls back to --dp-line (ADR 0018): it must stand out from the canvas.
  THEMES.each do |theme|
    it "#{theme} draws the track of meters distinguishably from the canvas (3:1)" do
      vars = CssVars.stop_vars.merge(CssVars.theme_vars(theme))
      track = CssVars.resolve("var(--dp-#{vars.key?('--dp-track') ? 'track' : 'line'})", vars)
      expect(CssVars.contrast(track, CssVars.resolve("var(--dp-canvas)", vars))).to be >= 3.0
    end
  end

  # high-contrast is the theme for people who need more than AA: its text is AAA (7:1) and its boundaries 4.5:1
  describe "high-contrast (AAA)" do
    let(:aaa) { rules.fetch("high_contrast") }
    let(:vars) { CssVars.stop_vars.merge(CssVars.theme_vars("high-contrast")) }
    let(:colour) { ->(name) { CssVars.resolve("var(--dp-#{name})", vars) } }

    it "reaches the text minimum on every text pair, role ink on role, and roles used as text" do
      text = rules["pairs"].select { _1["min"] >= 4.5 }.map { [ _1["fg"], _1["bg"] ] }
      text += (ROLES - [ "emergency" ]).map { [ "#{_1}-ink", _1 ] } # emergency: see below
      text += rules["roles_as_text"]["roles"].map { [ _1, "canvas" ] }
      failures = text.uniq.map { |fg, bg| [ fg, bg, CssVars.contrast(colour.(fg), colour.(bg)) ] }.select { |*, ratio| ratio < aaa["text_min"] }
      expect(failures).to be_empty, failures.map { |fg, bg, ratio| format("%s on %s %.2f", fg, bg, ratio) }.join("; ")
    end

    # Pure red is the emergency colour by convention. A red light enough for 7:1 text would look like danger (a lighter red), so the text on the
    # emergency fill stays at AA (documented exception, ADR 0018).
    it "keeps the text on the emergency fill at AA, the documented exception to AAA" do
      expect(CssVars.contrast(colour.("emergency-ink"), colour.("emergency"))).to be >= 4.5
    end

    # The filled part of a meter must stand out from its track, for every role that can colour one. Exempt: muted (subdued on purpose) and emergency
    # (pure red, an AA exception like its text).
    it "keeps every role used for a meter fill at 3:1 against the meter track" do
      track = colour.("track")
      failures = (ROLES - %w[muted emergency]).map { |role| [ role, CssVars.contrast(colour.(role), track) ] }.select { |_, ratio| ratio < 3.0 }
      expect(failures).to be_empty, failures.map { |role, ratio| format("%s on track %.2f", role, ratio) }.join("; ")
    end

    it "reaches the boundary minimum for the line, the focus ring and every role on the canvas and surfaces" do
      pairs = %w[canvas surface surface-raised].product(%w[line focus]).map(&:reverse) + ROLES.product(%w[canvas]).reject { |role, _| role == "emergency" }
      failures = pairs.map { |fg, bg| [ fg, bg, CssVars.contrast(colour.(fg), colour.(bg)) ] }.select { |*, ratio| ratio < aaa["ui_min"] }
      expect(failures).to be_empty, failures.map { |fg, bg, ratio| format("%s on %s %.2f", fg, bg, ratio) }.join("; ")
      expect(CssVars.contrast(colour.("emergency"), colour.("canvas"))).to be >= 4.5
    end
  end

  it "ships exactly the built-in themes (one stylesheet each)" do
    files = Dir[CssVars::ROOT.join("app/assets/stylesheets/deckplate/themes/*.css")].map { File.basename(_1, ".css") }
    expect(files.sort).to eq(THEMES.sort)
  end
end
