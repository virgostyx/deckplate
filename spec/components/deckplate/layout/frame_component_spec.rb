require "spec_helper"

RSpec.describe Deckplate::Layout::FrameComponent, type: :component do
  def render_frame(**opts, &block)
    render_inline(described_class.new(**opts)) do |f|
      f.with_header { "HEAD" }
      f.with_sidebar { "SIDE" }
      f.with_aside { "ASIDE" }
      f.with_main { "MAIN" }
      f.with_footer { "FOOT" }
      f.with_top_left_corner { "TL" }
      f.with_bottom_left_corner { "BL" }
      block&.call(f)
    end
  end

  it "renders the classic frame: header, sidebar, main, footer and the two left corners" do
    render_frame
    expect(page).to have_css(".dp-frame.dp-frame--classic")
    expect(page).to have_css(".dp-frame__grid > header.dp-frame__header", text: "HEAD")
    expect(page).to have_css(".dp-frame__sidebar", text: "SIDE", visible: :all)
    expect(page).to have_css("main.dp-frame__main", text: "MAIN")
    expect(page).to have_css("footer.dp-frame__footer", text: "FOOT")
    expect(page).to have_css(".dp-frame__corner--top-start", text: "TL")
    expect(page).to have_css(".dp-frame__corner--bottom-start", text: "BL")
    expect(page).not_to have_css(".dp-frame__aside")
  end

  it "adds the aside column in the double variant" do
    render_frame(variant: :double)
    expect(page).to have_css(".dp-frame--double aside.dp-frame__aside", text: "ASIDE")
    expect(page).to have_css(".dp-frame__sidebar", visible: :all)
  end

  it "keeps only header, main and footer in the minimal variant" do
    render_frame(variant: :minimal)
    expect(page).to have_css(".dp-frame--minimal header.dp-frame__header")
    expect(page).to have_css("main.dp-frame__main")
    expect(page).not_to have_css(".dp-frame__sidebar", visible: :all)
    expect(page).not_to have_css(".dp-frame__corner", visible: :all)
    expect(page).not_to have_css(".dp-frame__menu", visible: :all)
  end

  it "renders only the slots that were given" do
    render_inline(described_class.new) { |f| f.with_main { "MAIN" } }
    expect(page).to have_css("main.dp-frame__main", text: "MAIN")
    expect(page).not_to have_css(".dp-frame__header")
    expect(page).not_to have_css(".dp-frame__footer")
    expect(page).not_to have_css(".dp-frame__menu", visible: :all)
  end

  describe "collapsing sidebar (native popover, no JS)" do
    it "wires a menu button to the sidebar popover" do
      render_frame
      button = page.find(".dp-frame__menu", visible: :all)
      sidebar = page.find(".dp-frame__sidebar", visible: :all)
      expect(sidebar[:popover]).to eq("auto")
      expect(button[:popovertarget]).to eq(sidebar[:id])
      expect(button[:type]).to eq("button")
      expect(button.text(:all)).to eq("Menu")
    end

    it "translates the skip link" do
      I18n.with_locale(:fr) { render_frame }
      expect(page.find(".dp-frame__skip", visible: :all).text(:all)).to eq("Aller au contenu principal")
    end

    it "derives ids from the frame id (render-pure)" do
      render_frame(id: "app")
      expect(page).to have_css("#app-sidebar[popover]", visible: :all)
      expect(page).to have_css("#app-main", text: "MAIN")
      a = render_frame(id: "app").to_html
      expect(render_frame(id: "app").to_html).to eq(a)
    end
  end

  it "offers a skip link to the main content" do
    render_frame(id: "app")
    link = page.find(".dp-frame__skip", visible: :all)
    expect(link[:href]).to eq("#app-main")
  end

  describe "options" do
    it "can be fixed to the viewport height" do
      render_frame(fixed: true)
      expect(page).to have_css(".dp-frame.dp-frame--fixed")
    end

    it "makes main keyboard-focusable when it scrolls (fixed), so keyboard users can scroll it" do
      render_frame(fixed: true)
      expect(page.find("main.dp-frame__main")[:tabindex]).to eq("0")
    end

    it "leaves main out of the tab order when the page itself scrolls" do
      render_frame
      expect(page.find("main.dp-frame__main")[:tabindex]).to be_nil
    end

    it "can pin a theme on the frame" do
      render_frame(theme: :azure)
      expect(page).to have_css(".dp-frame[data-dp-theme='azure']")
    end

    it "passes class, data and aria through" do
      render_frame(class: "x", data: { a: 1 })
      expect(page).to have_css(".dp-frame.x[data-a='1']")
    end

    it "rejects invalid input" do
      expect { described_class.new(variant: :wide) }.to raise_error(ArgumentError, /variant.*classic, double, minimal/)
      expect { described_class.new(theme: :bogus) }.to raise_error(ArgumentError, /theme/)
    end
  end
end
