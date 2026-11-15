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

  describe "aria-describedby merging" do
    it "adds the component's ids to the caller's instead of replacing them" do
      stub_const("Deckplate::DescribedComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(**html_attributes(aria: { describedby: "hint-1 error-1", label: "Own" }))
      end)
      render_inline(Deckplate::DescribedComponent.new(aria: { describedby: "mine", label: "Theirs" }))
      el = page.find("div")
      expect(el["aria-describedby"]).to eq("hint-1 error-1 mine")
      expect(el["aria-label"]).to eq("Theirs") # other aria keys: caller wins
    end

    it "leaves the component's value alone when the caller gives none" do
      stub_const("Deckplate::DescribedComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(**html_attributes(aria: { describedby: "hint-1" }))
      end)
      render_inline(Deckplate::DescribedComponent.new)
      expect(page.find("div")["aria-describedby"]).to eq("hint-1")
    end
  end

  describe "dynamic CSS values (vars: and percent:)" do
    before do
      stub_const("Deckplate::DynamicComponent", Class.new(Deckplate::BaseComponent) do
        def initialize(vars: {}, percent: nil, **options)
          super(**options)
          @vars, @percent = vars, percent
        end

        def call = tag.div(**html_attributes(vars: @vars, percent: @percent))
      end)
    end

    after { Deckplate.reset_configuration! }

    it "writes custom properties in an inline style by default" do
      render_inline(Deckplate::DynamicComponent.new(vars: { "--dp-n": 2, "--dp-x": "1.5" }))
      expect(page.find("div")[:style]).to eq("--dp-n: 2; --dp-x: 1.5")
      expect(page.find("div")["data-controller"]).to be_nil
    end

    it "appends to the caller's inline style" do
      render_inline(Deckplate::DynamicComponent.new(vars: { "--dp-n": 2 }, style: "margin: 0"))
      expect(page.find("div")[:style]).to eq("--dp-n: 2; margin: 0")
    end

    it "passes a percentage as --dp-value" do
      render_inline(Deckplate::DynamicComponent.new(percent: 72.5))
      expect(page.find("div")[:style]).to eq("--dp-value: 72.5")
    end

    context "with csp_safe_values" do
      before { Deckplate.configure { |c| c.csp_safe_values = true } }

      it "emits no style attribute: the values travel in a data attribute applied by dp-values through the CSSOM" do
        render_inline(Deckplate::DynamicComponent.new(vars: { "--dp-n": 2, "--dp-x": "1.5" }))
        el = page.find("div")
        expect(el[:style]).to be_nil
        expect(el["data-controller"]).to eq("dp-values")
        expect(JSON.parse(el["data-dp-values-vars-value"])).to eq("--dp-n" => "2", "--dp-x" => "1.5")
      end

      it "wires the morph protection: the style attribute written through the CSSOM must survive a Turbo morph" do
        render_inline(Deckplate::DynamicComponent.new(vars: { "--dp-n": 2 }))
        expect(page.find("div")["data-action"]).to eq("turbo:before-morph-attribute->dp-values#keepState")
      end

      it "adds dp-values to the caller's controllers instead of replacing them" do
        render_inline(Deckplate::DynamicComponent.new(vars: { "--dp-n": 2 }, data: { controller: "mine" }))
        expect(page.find("div")["data-controller"]).to eq("dp-values mine")
      end

      it "turns a percentage into a quantised class and data-dp-value: no style, no JavaScript" do
        render_inline(Deckplate::DynamicComponent.new(percent: 72.4))
        el = page.find("div")
        expect(el[:class].split).to include("dp-v-72")
        expect(el["data-dp-value"]).to eq("72")
        expect(el[:style]).to be_nil
        expect(el["data-controller"]).to be_nil
      end

      it "clamps percentages to 0..100" do
        render_inline(Deckplate::DynamicComponent.new(percent: 140))
        expect(page.find("div")[:class].split).to include("dp-v-100")
        render_inline(Deckplate::DynamicComponent.new(percent: -3))
        expect(page.find("div")[:class].split).to include("dp-v-0")
      end
    end
  end

  describe "dynamic_attributes (for child elements of a component)" do
    before do
      stub_const("Deckplate::ChildAttrsComponent", Class.new(Deckplate::BaseComponent) do
        def call = tag.div(tag.span(**dynamic_attributes(classes: [ "child" ], percent: 40, vars: { "--dp-n": 3 })), class: "root")
      end)
    end

    after { Deckplate.reset_configuration! }

    it "returns class/data/style for a child, without the caller's html options" do
      render_inline(Deckplate::ChildAttrsComponent.new(class: "extra", id: "r"))
      child = page.find(".child")
      expect(child[:style]).to eq("--dp-n: 3; --dp-value: 40")
      expect(child[:id]).to be_nil
      expect(page.find(".root")[:class]).to eq("root")
    end

    it "follows the CSP-safe mode" do
      Deckplate.configure { |c| c.csp_safe_values = true }
      render_inline(Deckplate::ChildAttrsComponent.new)
      child = page.find(".child")
      expect(child[:style]).to be_nil
      expect(child[:class].split).to include("child", "dp-v-40")
      expect(child["data-dp-value"]).to eq("40")
      expect(JSON.parse(child["data-dp-values-vars-value"])).to eq("--dp-n" => "3")
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

    it "prefixes the modifier with the variant name when values would clash (prefix: true)" do
      stub_const("Deckplate::ClashComponent", Class.new(described_class) do
        variant :shape, %i[square start end], default: :square
        variant :align, %i[start center end], default: :end, prefix: true
        def call = tag.div(class: variant_classes)
      end)
      render_inline(Deckplate::ClashComponent.new)
      expect(page.find("div")[:class].split).to contain_exactly("dp-clash--square", "dp-clash--align-end")
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
