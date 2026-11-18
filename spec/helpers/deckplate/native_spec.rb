require "spec_helper"

# Hotwire Native (ADR 0019): the native clients add "Hotwire Native iOS; Turbo Native iOS;" (or Android) to the user agent.
RSpec.describe Deckplate::Helpers, type: :helper do
  after { Deckplate.reset_configuration! }

  def with_agent(agent) = helper.request.headers["User-Agent"] = agent

  describe "#dp_native?" do
    [ "MyApp/1.0 Hotwire Native iOS; Turbo Native iOS; bridge-components: [form menu];",
      "MyApp Hotwire Native Android; Turbo Native Android; bridge-components: [];",
      "Turbo Native iOS", # clients before the rename
      "hotwire native ios" ].each do |agent|
      it "is true for #{agent[0, 40].inspect}" do
        with_agent(agent)
        expect(helper.dp_native?).to be(true)
      end
    end

    [ "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/126 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1",
      "Hotwire", "Native", "", nil ].each do |agent|
      it "is false for #{agent.inspect[0, 40]}" do
        with_agent(agent)
        expect(helper.dp_native?).to be(false)
      end
    end
  end

  describe "#dp_theme_attrs in a native client" do
    it "adds data-dp-native, so the stylesheet can adapt (density, safe areas)" do
      with_agent("App Hotwire Native iOS; Turbo Native iOS;")
      expect(helper.dp_theme_attrs).to eq(data: { dp_theme: "classic", dp_native: "true" })
      expect(helper.tag.attributes(helper.dp_theme_attrs)).to eq('data-dp-theme="classic" data-dp-native="true"')
    end

    it "adds nothing in a browser" do
      with_agent("Mozilla/5.0 Chrome/126")
      expect(helper.dp_theme_attrs).to eq(data: { dp_theme: "classic" })
    end
  end
end
