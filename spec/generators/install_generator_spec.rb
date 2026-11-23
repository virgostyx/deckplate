require "spec_helper"
require "generators/deckplate/install/install_generator"

RSpec.describe Deckplate::Generators::InstallGenerator do
  let(:root) { FixtureApp.build }
  after { FileUtils.remove_entry(root) if root && File.exist?(root) }

  # Runs the generator in the fixture tree and returns what it printed
  def run_install(destination = root, args = [])
    out = StringIO.new
    original = $stdout
    $stdout = out
    described_class.start(args, destination_root: destination)
    out.string
  ensure
    $stdout = original
  end

  describe "initializer" do
    it "creates config/initializers/deckplate.rb with every option documented" do
      run_install
      content = FixtureApp.read(root, "config/initializers/deckplate.rb")
      %w[default_theme themes sounds csp_safe_values strict_colors form_builder].each { expect(content).to include("c.#{_1}") }
      expect { RubyVM::InstructionSequence.compile(content) }.not_to raise_error
    end

    it "does not overwrite an initializer the host already edited" do
      FixtureApp.write(root, "config/initializers/deckplate.rb", "Deckplate.configure { |c| c.sounds = true }\n")
      run_install
      expect(FixtureApp.read(root, "config/initializers/deckplate.rb")).to eq("Deckplate.configure { |c| c.sounds = true }\n")
    end
  end

  describe "layout" do
    it "adds the font preload and the stylesheet before the app stylesheet, the theme attributes on <html> and dp-root on <body>" do
      run_install
      layout = FixtureApp.read(root, "app/views/layouts/application.html.erb")
      expect(layout).to include('<html lang="<%= I18n.locale %>" <%= tag.attributes(dp_theme_attrs) %>>')
      expect(layout).to include('<body class="dp-root">')
      expect(layout).to include("<%= dp_font_tags %>")
      expect(layout.index('stylesheet_link_tag "deckplate"')).to be < layout.index("stylesheet_link_tag :app")
      expect(layout.index("dp_font_tags")).to be < layout.index('stylesheet_link_tag "deckplate"')
    end

    it "keeps the rest of the layout byte for byte" do
      run_install
      layout = FixtureApp.read(root, "app/views/layouts/application.html.erb")
      FixtureApp::LAYOUT.lines.each { |line| expect(layout).to include(line.strip) unless line.match?(/<html>|<body>/) }
    end

    it "gives <html> a lang attribute (axe html-has-lang), without duplicating one the layout already has" do
      FixtureApp.write(root, "app/views/layouts/application.html.erb", FixtureApp::LAYOUT.sub("<html>", '<html lang="fr">'))
      run_install
      html_tag = FixtureApp.read(root, "app/views/layouts/application.html.erb")[/<html[^>]*>\z?/m]
      expect(html_tag.scan("lang=").size).to eq(1)
      expect(html_tag).to include('lang="fr"', "dp_theme_attrs")
    end

    it "adds dp-root to an existing body class instead of replacing it" do
      FixtureApp.write(root, "app/views/layouts/application.html.erb", FixtureApp::LAYOUT.sub("<body>", '<body class="host-body">'))
      run_install
      expect(FixtureApp.read(root, "app/views/layouts/application.html.erb")).to include('<body class="dp-root host-body">')
    end

    it "does not guess when <html> or <body> already hold ERB: it prints the exact lines to add" do
      tricky = FixtureApp::LAYOUT.sub("<html>", '<html lang="<%= I18n.locale %>">').sub("<body>", '<body class="<%= controller_name %>">')
      FixtureApp.write(root, "app/views/layouts/application.html.erb", tricky)
      output = run_install
      layout = FixtureApp.read(root, "app/views/layouts/application.html.erb")
      expect(layout).to include('<html lang="<%= I18n.locale %>">', '<body class="<%= controller_name %>">')
      expect(output).to include("tag.attributes(dp_theme_attrs)").and include("dp-root")
    end

    it "prints instructions when there is no layout" do
      FileUtils.rm_f(File.join(root, "app/views/layouts/application.html.erb"))
      expect(run_install).to include('stylesheet_link_tag "deckplate"')
    end

    it "falls back to the end of <head> when the layout has no stylesheet tag" do
      FixtureApp.write(root, "app/views/layouts/application.html.erb", FixtureApp::LAYOUT.sub(/^ *<%= stylesheet_link_tag.*\n/, ""))
      run_install
      layout = FixtureApp.read(root, "app/views/layouts/application.html.erb")
      expect(layout.index('stylesheet_link_tag "deckplate"')).to be < layout.index("</head>")
    end
  end

  describe "Stimulus" do
    it "registers the controllers in controllers/index.js" do
      run_install
      js = FixtureApp.read(root, "app/javascript/controllers/index.js")
      expect(js).to include('import { registerDeckplate } from "deckplate"').and include("registerDeckplate(application)")
      expect(js).to include("eagerLoadControllersFrom") # untouched
    end

    it "prints instructions when the host has no importmap or no Stimulus index" do
      bare = FixtureApp.build(importmap: false, stimulus: false)
      output = run_install(bare)
      expect(output).to include("registerDeckplate").and include("importmap")
      expect(FixtureApp.exist?(bare, "app/javascript/controllers/index.js")).to be(false)
      FileUtils.remove_entry(bare)
    end
  end

  describe "Tailwind" do
    let(:tw) { FixtureApp.build(tailwind: true) }
    after { FileUtils.remove_entry(tw) }

    it "puts the layer prelude on the first line of the Tailwind source (ADR 0003)" do
      run_install(tw)
      css = FixtureApp.read(tw, "app/assets/tailwind/application.css")
      expect(css.lines.first.strip).to eq("@layer theme, base, dp, components, utilities;")
      expect(css).to include('@import "tailwindcss";')
    end

    it "copies the bridge into the host and imports it after Tailwind (ADR 0016)" do
      run_install(tw)
      css = FixtureApp.read(tw, "app/assets/tailwind/application.css")
      expect(css.index('@import "tailwindcss";')).to be < css.index('@import "./deckplate-bridge.css";')
      expect(FixtureApp.read(tw, "app/assets/tailwind/deckplate-bridge.css")).to include("@theme inline {", "--color-dp-primary: var(--dp-primary);")
    end

    it "prints the import to add when the Tailwind source has no @import \"tailwindcss\"" do
      FixtureApp.write(tw, "app/assets/tailwind/application.css", "@tailwind base;\n")
      expect(run_install(tw)).to include('@import "./deckplate-bridge.css";')
    end

    it "leaves the CSS alone without Tailwind" do
      run_install
      expect(FixtureApp.exist?(root, "app/assets/tailwind/application.css")).to be(false)
      expect(FixtureApp.exist?(root, "app/assets/tailwind/deckplate-bridge.css")).to be(false)
    end
  end

  describe "idempotency" do
    it "changes nothing on a second run, and says so" do
      run_install
      first = FixtureApp.snapshot(root)
      second_output = run_install
      expect(FixtureApp.snapshot(root)).to eq(first)
      expect(second_output).to match(/already/i)
    end

    it "is idempotent with Tailwind too" do
      tw = FixtureApp.build(tailwind: true)
      run_install(tw)
      first = FixtureApp.snapshot(tw)
      run_install(tw)
      expect(FixtureApp.snapshot(tw)).to eq(first)
      FileUtils.remove_entry(tw)
    end

    it "recognises a layout the host wired by hand" do
      FixtureApp.write(root, "app/views/layouts/application.html.erb", FixtureApp::LAYOUT.sub("<head>", "<head>\n    <%= stylesheet_link_tag \"deckplate\" %>"))
      run_install
      expect(FixtureApp.read(root, "app/views/layouts/application.html.erb").scan('stylesheet_link_tag "deckplate"').size).to eq(1)
    end
  end

  it "prints a summary of what it did and the next steps" do
    output = run_install
    expect(output).to include("Deckplate installed").and include("dp_toast_container")
  end
end
