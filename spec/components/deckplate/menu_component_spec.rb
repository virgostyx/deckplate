require "spec_helper"

RSpec.describe Deckplate::MenuComponent, type: :component do
  def render_menu(**opts)
    render_inline(described_class.new(label: "Actions", **opts)) do |m|
      m.with_item(label: "Edit", href: "/ships/1/edit")
      m.with_item(label: "Archive", href: "/ships/1/archive", method: :post)
      m.with_item(label: "Delete", href: "/ships/1", method: :delete)
    end
  end

  it "renders a trigger button wired to a popover menu" do
    render_menu(id: "ship-menu")
    trigger = page.find("button[aria-haspopup='menu']", visible: :all)
    expect(trigger[:popovertarget]).to eq("ship-menu")
    expect(trigger["aria-expanded"]).to eq("false")
    expect(trigger.text(:all)).to include("Actions")
    menu = page.find("#ship-menu", visible: :all)
    expect(menu[:popover]).to eq("auto")
    expect(menu[:role]).to eq("menu")
    expect(menu["aria-label"]).to eq("Actions")
  end

  it "derives a deterministic id from the label" do
    render_menu
    expect(page).to have_css("#actions-menu[popover]", visible: :all)
    expect(render_menu.to_html).to eq(render_menu.to_html)
  end

  it "renders links and form buttons as menu items with a roving tabindex" do
    render_menu(id: "m")
    expect(page).to have_css("a[role='menuitem'][href='/ships/1/edit'][tabindex='-1']", text: "Edit", visible: :all)
    expect(page).to have_css("form.dp-menu__form button[role='menuitem'][tabindex='-1']", text: "Archive", visible: :all)
    expect(page).to have_css("form input[name='_method'][value='delete']", visible: :all)
    expect(page).to have_css("[role='menuitem']", count: 3, visible: :all)
  end

  it "wires the controller" do
    render_menu(id: "m")
    expect(page).to have_css(".dp-menu[data-controller='dp-menu']", visible: :all)
    expect(page.find("#m", visible: :all)["data-dp-menu-target"]).to eq("list")
    expect(page.find("#m", visible: :all)["data-action"]).to include("toggle->dp-menu#toggled", "keydown->dp-menu#keydown")
    expect(page.find("button[aria-haspopup]", visible: :all)["data-action"]).to include("keydown->dp-menu#triggerKey")
  end

  it "colours the trigger and passes html options to the wrapper" do
    render_menu(color: :tertiary, class: "x")
    expect(page).to have_css(".dp-menu.x button.dp-c-tertiary", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "") }.to raise_error(ArgumentError, /label/)
    expect { render_inline(described_class.new(label: "A")) }.to raise_error(ArgumentError, /item/)
    expect { Deckplate::MenuItemComponent.new(label: "", href: "/") }.to raise_error(ArgumentError, /label/)
    expect { Deckplate::MenuItemComponent.new(label: "A", href: "") }.to raise_error(ArgumentError, /href/)
  end
end
