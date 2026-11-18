require "spec_helper"

# Touch and Hotwire Native rules (ADR 0019), checked on the source stylesheets.
RSpec.describe "Touch and native stylesheet rules" do
  let(:sources) { Dir[Deckplate::Engine.root.join("app/assets/stylesheets/deckplate/**/*.css")].sort }

  # Walks a stylesheet and yields [selector text, enclosing @media conditions] for every rule with a body
  def each_rule(css)
    css = css.gsub(%r{/\*.*?\*/}m, "")
    stack = []
    css.scan(/([^{};]+)\{|\}/) do |match|
      if (head = match[0])
        head = head.strip
        stack.push(head)
        yield head, stack[0..-2].grep(/\A@media/) unless head.start_with?("@")
      else
        stack.pop
      end
    end
  end

  it "applies hover styles only where there is a hover (a tap must not leave a sticky hover on a touch screen)" do
    unguarded = sources.flat_map do |file|
      found = []
      each_rule(File.read(file)) { |selector, media| found << "#{File.basename(file)}: #{selector}" if selector.include?(":hover") && media.none? { _1.include?("(hover: hover)") } }
      found
    end
    expect(unguarded).to eq([])
  end

  it "finds the hover rules it is meant to guard (the check is not vacuous)" do
    count = sources.sum { |file| n = 0; each_rule(File.read(file)) { |selector, _| n += 1 if selector.include?(":hover") }; n }
    expect(count).to be >= 8
  end

  describe "native clients ([data-dp-native])" do
    let(:css) { sources.map { File.read(_1) }.join("\n") }

    it "makes touch targets larger than the default 44 px (48 px, the Android minimum)" do
      expect(css).to match(/\[data-dp-native\][^{]*\{[^}]*--dp-touch-min:\s*3rem/)
    end

    it "removes the tap highlight and the double-tap delay on controls" do
      expect(css).to match(/\[data-dp-native\][^{]*\{[^}]*-webkit-tap-highlight-color:\s*transparent/)
      expect(css).to match(/\[data-dp-native\][^{]*\{[^}]*touch-action:\s*manipulation/)
    end
  end

  describe "safe areas (notch, home indicator)" do
    it "keeps fixed toasts and the fixed frame clear of the device insets, with a zero fallback" do
      toast = File.read(Deckplate::Engine.root.join("app/assets/stylesheets/deckplate/components/feedback/toast.css"))
      frame = File.read(Deckplate::Engine.root.join("app/assets/stylesheets/deckplate/layout/frame.css"))
      expect(toast).to include("env(safe-area-inset-bottom")
      expect(frame).to include("env(safe-area-inset-top")
    end
  end
end
