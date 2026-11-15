require "spec_helper"

RSpec.describe Deckplate::BaseComponent, type: :component do
  def render_demo(**opts)
    render_inline(Deckplate::DemoComponent.new(**opts))
    page.find("div")
  end

  describe "block name" do
    it "derives dp-<name> from the class name" do
      expect(Deckplate::DemoComponent.block_name).to eq("dp-demo")
    end

    it "handles nested namespaces and multi-word names" do
      stub_const("Deckplate::Forms::TextInputComponent", Class.new(described_class))
      expect(Deckplate::Forms::TextInputComponent.block_name).to eq("dp-text-input")
    end
  end

  describe "class merging" do
    it "keeps the component classes and appends the caller's (never replaces)" do
      el = render_demo(class: "mine extra")
      expect(el[:class].split).to include("dp-demo", "dp-demo--md", "dp-demo--pill", "mine", "extra")
    end

    it "accepts an array of classes and ignores nil/blank entries" do
      el = render_demo(class: [ "a", nil, "", "b" ])
      expect(el[:class].split).to include("a", "b")
      expect(el[:class]).not_to match(/  /)
    end
  end

  describe "data and aria deep merge" do
    it "passes data-* and aria-* attributes through" do
      el = render_demo(data: { turbo_permanent: true }, aria: { label: "Hello" })
      expect(el["data-turbo-permanent"]).to eq("true")
      expect(el["aria-label"]).to eq("Hello")
    end

    it "lets the caller override component defaults for plain keys" do
      stub_const("Deckplate::DefaultsComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(**html_attributes(data: { mode: "default", other: "x" }))
      end)
      render_inline(Deckplate::DefaultsComponent.new(data: { mode: "custom" }))
      expect(page.find("div")["data-mode"]).to eq("custom")
      expect(page.find("div")["data-other"]).to eq("x")
    end

    it "concatenates data-controller and data-action instead of replacing them" do
      stub_const("Deckplate::TokensComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(**html_attributes(data: { controller: "dp-tabs", action: "click->dp-tabs#go" }))
      end)
      render_inline(Deckplate::TokensComponent.new(data: { controller: "mine", action: "focus->mine#a" }))
      el = page.find("div")
      expect(el["data-controller"]).to eq("dp-tabs mine")
      expect(el["data-action"]).to eq("click->dp-tabs#go focus->mine#a")
    end
  end

  describe "style merging" do
    it "appends the caller's inline style after the component's, never replacing it" do
      stub_const("Deckplate::StyledComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(**html_attributes(style: "--dp-n: 3"))
      end)
      render_inline(Deckplate::StyledComponent.new(style: "margin: 0"))
      expect(page.find("div")[:style]).to eq("--dp-n: 3; margin: 0")
    end

    it "keeps the component style when the caller gives none" do
      stub_const("Deckplate::StyledComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(**html_attributes(style: "--dp-n: 3;"))
      end)
      render_inline(Deckplate::StyledComponent.new)
      expect(page.find("div")[:style]).to eq("--dp-n: 3")
    end
  end

  describe "id and other attributes" do
    it "passes id and arbitrary attributes through" do
      el = render_demo(id: "x1", title: "T", lang: "fr")
      expect(el[:id]).to eq("x1")
      expect(el[:title]).to eq("T")
      expect(el[:lang]).to eq("fr")
    end
  end

  describe "variants" do
    it "uses the default when nothing is given" do
      expect(render_demo[:class].split).to include("dp-demo--md", "dp-demo--pill")
    end

    it "applies a valid variant" do
      expect(render_demo(size: :lg)[:class].split).to include("dp-demo--lg")
    end

    it "accepts a string value" do
      expect(render_demo(size: "sm")[:class].split).to include("dp-demo--sm")
    end

    it "raises ArgumentError listing valid values for an invalid one" do
      expect { render_demo(size: :huge) }.to raise_error(ArgumentError, /size.*:huge.*sm, md, lg/)
    end

    it "rejects unknown variant names" do
      expect { Deckplate::DemoComponent.new.send(:assign_variants, colour: :x) }.to raise_error(ArgumentError, /unknown variant :colour/)
    end

    it "inherits variants in subclasses without leaking to the parent" do
      child = Class.new(Deckplate::DemoComponent) { variant :tone, %i[a b], default: :a }
      expect(child.variant_definitions.keys).to eq(%i[size shape tone])
      expect(Deckplate::DemoComponent.variant_definitions.keys).to eq(%i[size shape])
    end
  end

  describe "colours" do
    it "maps a role to its colour class" do
      expect(render_demo(color: :danger)[:class].split).to include("dp-c-danger")
    end

    it "maps a palette stop (underscores in Ruby, hyphens in CSS)" do
      expect(render_demo(color: :neon_carrot)[:class].split).to include("dp-c-neon-carrot")
    end

    it "raises ArgumentError listing valid colours when strict" do
      expect { render_demo(color: :blurple) }.to raise_error(ArgumentError, /unknown colou?r :blurple.*primary.*neon_carrot/m)
    end

    it "rejects hyphenated names (Ruby side uses underscores)" do
      expect { render_demo(color: :"neon-carrot") }.to raise_error(ArgumentError)
    end

    it "falls back to primary and logs a warning when not strict" do
      Deckplate.configure { |c| c.strict_colors = false }
      allow(Rails.logger).to receive(:warn)
      expect(render_demo(color: :blurple)[:class].split).to include("dp-c-primary")
      expect(Rails.logger).to have_received(:warn).with(/unknown colou?r :blurple/)
    ensure
      Deckplate.reset_configuration!
    end

    it "knows every role and every palette stop" do
      stops = YAML.load_file(Deckplate::Engine.root.join("config/deckplate/palette.yml")).fetch("stops").keys.map { _1.tr("-", "_").to_sym }
      expect(Deckplate::Concerns::Colorable.valid_colors).to include(*Deckplate::Concerns::Colorable::ROLES, *stops)
    end
  end

  describe "sizes in layout units" do
    let(:component) { described_class.new }

    it "turns numbers into multiples of --dp-u" do
      expect(component.send(:u, 3)).to eq("calc(3 * var(--dp-u))")
      expect(component.send(:u, 1.5)).to eq("calc(1.5 * var(--dp-u))")
    end

    it "rejects non-numbers and negatives" do
      expect { component.send(:u, "3") }.to raise_error(ArgumentError, /number/)
      expect { component.send(:u, -1) }.to raise_error(ArgumentError, /negative|>= 0/)
    end
  end
end
