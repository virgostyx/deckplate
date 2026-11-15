require "spec_helper"

RSpec.describe "Theme contrast (WCAG 2.2 AA)" do
  THEMES = %w[classic azure nocturne daylight crimson].freeze
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

  it "ships the five themes of SPEC 5.5" do
    files = Dir[CssVars::ROOT.join("app/assets/stylesheets/deckplate/themes/*.css")].map { File.basename(_1, ".css") }
    expect(files.sort).to eq(THEMES.sort)
  end
end
