require "spec_helper"
require "generators/deckplate/install/install_generator"
require "generators/deckplate/theme/theme_generator"

RSpec.describe Deckplate::Generators::ThemeGenerator do
  let(:root) { FixtureApp.build }
  after { FileUtils.remove_entry(root) if root && File.exist?(root) }

  def run(name, destination = root)
    out = StringIO.new
    original = [ $stdout, $stderr ]
    $stdout = $stderr = out
    described_class.start([ name ], destination_root: destination)
    out.string
  ensure
    $stdout, $stderr = original
  end

  def installed_root
    original = $stdout
    $stdout = StringIO.new
    Deckplate::Generators::InstallGenerator.start([], destination_root: root)
    root
  ensure
    $stdout = original
  end

  let(:css_path) { "app/assets/stylesheets/deckplate-theme-ocean.css" }

  it "creates a stylesheet that starts from the classic mapping, under the theme's own selector" do
    run("ocean")
    css = FixtureApp.read(root, css_path)
    expect(css.lines.first).to include("@layer theme, base, dp, components, utilities;")
    expect(css).to include('[data-dp-theme="ocean"]')
    expect(css).not_to include('[data-dp-theme="classic"]')
    expect(css).to match(/@layer dp\.tokens\s*\{/)
  end

  it "defines every token a theme must define (the contrast spec's list)" do
    run("ocean")
    css = FixtureApp.read(root, css_path)
    roles = %w[primary secondary tertiary accent muted info success warning danger emergency]
    names = roles.flat_map { [ "--dp-#{_1}", "--dp-#{_1}-ink" ] } + %w[canvas surface surface-raised ink ink-muted line focus disabled].map { "--dp-#{_1}" }
    names.each { |name| expect(css).to match(/#{Regexp.escape(name)}:/), "missing #{name}" }
  end

  it "rejects an invalid name without writing anything" do
    expect(run("Ocean Blue")).to match(/invalid theme name/)
    expect(FixtureApp.snapshot(root)).to eq(FixtureApp.snapshot(FixtureApp.build))
  end

  it "rejects the names of the built-in themes" do
    before = FixtureApp.snapshot(root)
    expect(run("classic")).to match(/built-in/)
    expect(FixtureApp.snapshot(root)).to eq(before)
  end

  it "adds the theme to the initializer's list" do
    installed_root
    run("ocean")
    expect(FixtureApp.read(root, "config/initializers/deckplate.rb")).to include("c.themes          = %i[classic azure nocturne daylight crimson verdant high-contrast ocean]")
  end

  it "prints the line to add when the initializer is missing or customised" do
    expect(run("ocean")).to include("config.themes").and include("ocean")
  end

  it "links the stylesheet after Deckplate's own in the layout" do
    installed_root
    run("ocean")
    layout = FixtureApp.read(root, "app/views/layouts/application.html.erb")
    expect(layout.index('stylesheet_link_tag "deckplate"')).to be < layout.index('stylesheet_link_tag "deckplate-theme-ocean"')
    expect(layout.index('stylesheet_link_tag "deckplate-theme-ocean"')).to be < layout.index("stylesheet_link_tag :app")
  end

  it "is idempotent" do
    installed_root
    run("ocean")
    first = FixtureApp.snapshot(root)
    output = run("ocean")
    expect(FixtureApp.snapshot(root)).to eq(first)
    expect(output).to match(/already|exist/i)
  end

  it "keeps a theme file the host already edited" do
    FixtureApp.write(root, css_path, "/* mine */\n")
    run("ocean")
    expect(FixtureApp.read(root, css_path)).to eq("/* mine */\n")
  end
end
