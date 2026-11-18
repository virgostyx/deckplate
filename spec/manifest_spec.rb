require "spec_helper"
require "yaml"
require_relative "../tools/manifest_builder"

# config/deckplate/components.yml: the machine-readable catalogue of every component (parameters, defaults, variants, slots, controllers,
# stylesheet, previews), for docs and for ports (Django, Phoenix, plain HTML). Generated from the code by bin/build-manifest: never edited by hand.
RSpec.describe "Component manifest" do
  let(:root) { Deckplate::Engine.root }
  let(:path) { root.join(DeckplateBuild::ManifestBuilder::PATH) }
  let(:manifest) { YAML.load_file(path) }
  let(:components) { manifest.fetch("components") }
  let(:builder) { DeckplateBuild::ManifestBuilder.new(root) }

  before(:all) { Rails.autoloaders.main.eager_load }

  def klass(entry) = entry.fetch("class").constantize

  it "is up to date with the code (run bin/build-manifest)" do
    expect(path.read).to eq(builder.yaml), "components.yml is stale: run bin/build-manifest"
  end

  it "ignores components the specs create on the fly (anonymous classes, test doubles)" do
    Class.new(Deckplate::BaseComponent)
    stub_const("Deckplate::SpecOnlyComponent", Class.new(Deckplate::BaseComponent))
    expect(path.read).to eq(builder.yaml)
    expect(builder.yaml).not_to include("SpecOnly")
  end

  it "ships in the gem" do
    spec = Gem::Specification.load(root.join("deckplate.gemspec").to_s)
    expect(spec.files).to include("config/deckplate/components.yml")
  end

  it "declares its format and the conventions shared by every component" do
    expect(manifest["format"]).to eq(1)
    expect(manifest["common"]["html_options"]).to be_a(String)
    expect(manifest["common"]["colors"]).to match_array(%w[primary secondary tertiary accent muted info success warning danger emergency])
  end

  describe "coverage" do
    it "has an entry for every component class, and no other" do
      classes = Dir[root.join("app/components/**/*_component.rb")].map { |file| file.delete_prefix("#{root}/app/components/").delete_suffix(".rb").camelize }.sort - [ "Deckplate::BaseComponent" ]
      expect(components.values.map { _1["class"] }.sort).to eq(classes)
    end

    it "keys entries by the public name: namespace and class without the Component suffix" do
      expect(components.keys).to include("Button", "Forms::TextInput", "Data::Table", "Shapes::Elbow", "Layout::Frame", "Feedback::Toast")
      components.each { |key, entry| expect(entry["class"]).to eq("Deckplate::#{key}Component") }
    end

    it "lists the entries in a stable (sorted) order" do
      expect(components.keys).to eq(components.keys.sort)
    end
  end

  describe "every entry" do
    it "has a description taken from the doc comment above its class" do
      components.each do |key, entry|
        expect(entry["description"].to_s.strip).not_to be_empty, "#{key} has no doc comment above its class"
      end
    end

    it "names the shipped stylesheet it belongs to, matching its place in the stylesheet tree" do
      components.each do |key, entry|
        expect(%w[core controls forms data feedback]).to include(entry["sheet"]), key
        next unless entry["stylesheet"]

        expected = entry["stylesheet"][%r{components/(controls|forms|data|feedback)/}, 1] || "core"
        expect(entry["sheet"]).to eq(expected), "#{key}: #{entry['stylesheet']} is in the #{expected} sheet, not #{entry['sheet']}"
      end
    end

    it "points at its own stylesheet when it has one, and that file styles its block" do
      components.each do |key, entry|
        expect(entry.key?("css_block")).to eq(entry.key?("stylesheet")), key
        next unless entry["stylesheet"]

        css = root.join(entry["stylesheet"])
        expect(css).to exist, "#{key}: #{css}"
        expect(css.read).to include(".#{entry['css_block']}"), "#{key}: #{entry['stylesheet']} does not style .#{entry['css_block']}"
      end
    end

    it "has no own stylesheet only when it reuses the classes of another component: form controls and the parts of a slot" do
      without = components.reject { |_, e| e["stylesheet"] || e["abstract"] }.keys
      expect(without).to match_array(%w[Forms::Checkbox Forms::DateInput Forms::FileInput Forms::Range Forms::Select Forms::TextInput Forms::Textarea
                                        MenuItem NavItem Shapes::BarSegment SoundToggle Tab])
    end

    it "lists the Stimulus controllers it attaches, and those it only calls on an ancestor (talks_to); they all exist" do
      known = Dir[root.join("app/javascript/deckplate/controllers/dp_*_controller.js")].map { File.basename(_1)[/dp_(.*)_controller/, 1].tr("_", "-").prepend("dp-") }
      components.each do |key, entry|
        used = entry.fetch("controllers", []) + entry.fetch("talks_to", [])
        expect(known & used).to match_array(used), key
      end
      expect(components["Modal"]["controllers"]).to eq([ "dp-modal" ])
      expect(components["Forms::Keypad"]["controllers"]).to eq([ "dp-keypad" ])
      expect(components["Button"]).not_to have_key("controllers")
      expect(components["Button"]["talks_to"]).to eq([ "dp-sound" ]) # the tick, when config.sounds is on
      expect(components["Forms::FormField"]["controllers"]).to eq([ "dp-field" ])
    end

    # FormField wraps every form control and is shown by all their previews
    NO_OWN_PREVIEW = %w[Forms::FormField].freeze

    it "has at least one Lookbook preview that exists, unless it is only used through a slot, abstract, or listed above" do
      all = ViewComponent::Preview.all.flat_map { |p| p.examples.map { |e| "#{p.preview_name}/#{e}" } }
      components.each do |key, entry|
        entry.fetch("previews", []).each { |name| expect(all).to include(name), "#{key}: #{name}" }
        next if entry["abstract"] || entry["slot_of"] || NO_OWN_PREVIEW.include?(key)

        expect(entry["previews"]).not_to be_nil, "#{key} has no preview (Definition of Done, item 4)"
      end
    end
  end

  describe "parameters" do
    it "match the constructor: names, order and which ones are required" do
      components.each do |key, entry|
        actual = klass(entry).instance_method(:initialize).parameters.reject { |kind, _| kind == :keyrest }
        expect(entry.fetch("params", {}).keys).to eq(actual.map { _2.to_s }), key
        actual.each { |kind, name| expect(entry["params"][name.to_s]["required"]).to be(kind == :keyreq), "#{key}.#{name}" }
      end
    end

    it "flags the components that pass extra options to their element" do
      expect(components["Button"]["html_options"]).to be(true)
      expect(components["Forms::TextInput"]["html_options"]).to be(true)
    end

    it "gives the source of every default, as written in the constructor" do
      expect(components["Button"]["params"]["color"]["default"]).to eq(":primary")
      expect(components["Button"]["params"]["type"]["default"]).to eq('"button"')
      expect(components["Button"]["params"]["disabled"]["default"]).to eq("false")
      expect(components["Forms::TextInput"]["params"]["type"]["default"]).to eq(":text")
      expect(components["Data::Timeline"]["params"]["color"]["default"]).to eq(":primary")
    end

    it "has no default for a required parameter" do
      expect(components["Forms::Control"]["params"]["name"]).to eq("required" => true)
      expect(components["Layout::Panel"]["params"]["title"]).to eq("required" => true)
    end

    it "describes a variant by its values and default, from the Variants declaration" do
      shape = components["Button"]["params"]["shape"]
      expect(shape).to eq("required" => false, "variant" => { "values" => %w[pill block start end], "default" => "pill" })
      expect(components["Data::StatusPill"]["params"]["status"]).to include("required" => true, "variant" => include("values" => include("ok", "fail")))
      expect(components["Shapes::Elbow"]["params"]["corner"]["variant"]["values"]).to include("top_left", "top_start", "bottom_end")
    end

    it "reports every declared variant of the code" do
      components.each do |key, entry|
        klass(entry).variant_definitions.each do |name, definition|
          reported = entry["params"][name.to_s]["variant"]
          expect(reported).to eq("values" => definition[:values].map(&:to_s), "default" => definition[:default].to_s), "#{key}.#{name}"
        end
      end
    end

    it "lets a control say that it extends the shared form control instead of repeating its parameters" do
      expect(components["Forms::TextInput"]["extends"]).to eq("Forms::Control")
      expect(components["Forms::Control"]["abstract"]).to be(true)
      expect(components["Forms::Control"]["params"].keys).to include("name", "label", "hint", "errors", "required", "disabled", "alert")
      expect(components["Forms::TextInput"]["params"].keys).to eq(%w[type value])
    end
  end

  describe "slots" do
    it "match the declared slots, with their cardinality" do
      components.each do |key, entry|
        actual = klass(entry).registered_slots
        expect(entry.fetch("slots", {}).keys).to match_array(actual.keys.map(&:to_s)), key
        actual.each { |name, slot| expect(entry["slots"][name.to_s]["many"]).to be(slot[:collection] ? true : false), "#{key}.#{name}" }
      end
    end

    it "names the parameters a slot takes (slots defined by a lambda) or the component it renders" do
      events = components["Data::Timeline"]["slots"]["events"]
      expect(events).to include("many" => true)
      expect(events["params"].keys).to eq(%w[title time datetime state color])
      expect(events["params"]["title"]).to eq("required" => true)
      expect(events["params"]["state"]["default"]).to eq(":done")
      expect(components["Menu"]["slots"]["items"]["component"]).to eq("MenuItem")
    end

    it "marks the components that only exist as the content of a slot" do
      expect(components["MenuItem"]["slot_of"]).to eq([ "Menu" ])
      expect(components["Button"]).not_to have_key("slot_of")
    end
  end
end
