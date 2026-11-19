require "spec_helper"

RSpec.describe Deckplate::Data::SortableListComponent, type: :component do
  let(:items) { [ [ "a", "Alpha" ], [ "b", "Beta" ], [ "c", "Gamma" ] ] }

  def list(**options) = render_inline(described_class.new(label: "Boarding order", items: items, **options))
  def labels = page.all(".dp-sortable__label", visible: :all).map { _1.text(:all) }

  it "is a named ordered list with one item per entry, in the given order" do
    list
    expect(page).to have_css("div.dp-sortable[data-controller='dp-sortable'] ol.dp-sortable__list[aria-label='Boarding order']", visible: :all)
    expect(labels).to eq(%w[Alpha Beta Gamma])
    expect(page.all("li.dp-sortable__item", visible: :all).map { _1["data-dp-sortable-id"] }).to eq(%w[a b c])
  end

  it "gives every item real buttons to move it up and down, named after the item" do
    list
    ups = page.all("button[data-action='dp-sortable#move'][data-dp-sortable-direction-param='-1']", visible: :all)
    downs = page.all("button[data-action='dp-sortable#move'][data-dp-sortable-direction-param='1']", visible: :all)
    expect(ups.map { _1["aria-label"] }).to eq([ "Move Alpha up", "Move Beta up", "Move Gamma up" ])
    expect(downs.map { _1["aria-label"] }).to eq([ "Move Alpha down", "Move Beta down", "Move Gamma down" ])
    expect(page.all("button", visible: :all).map { _1[:type] }.uniq).to eq([ "button" ])
  end

  it "adds a decorative grip for the pointer" do
    list
    grips = page.all(".dp-sortable__grip", visible: :all)
    expect(grips.size).to eq(3)
    expect(grips.map { _1["aria-hidden"] }.uniq).to eq([ "true" ])
    expect(grips.first["data-action"]).to eq("pointerdown->dp-sortable#grab")
  end

  it "follows a drag on the list itself, whose pointer capture never moves" do
    list
    expect(page.find(".dp-sortable", visible: :all)["data-action"]).to eq("pointermove->dp-sortable#drag pointerup->dp-sortable#drop pointercancel->dp-sortable#drop")
  end

  it "announces moves in a polite live region and passes the message template to the controller" do
    list
    expect(page).to have_css("[role='status'][data-dp-sortable-target='status']", visible: :all)
    expect(page.find(".dp-sortable", visible: :all)["data-dp-sortable-moved-template-value"]).to eq("%{item} moved to position %{position} of %{total}")
  end

  it "submits the order with a form: a hidden field per item, in the list's order, when name: is given" do
    list(name: "crew[order][]")
    fields = page.all("input[type='hidden'][name='crew[order][]']", visible: :all)
    expect(fields.map { _1[:value] }).to eq(%w[a b c])
    list
    expect(page).not_to have_css("input", visible: :all)
  end

  it "accepts a Hash and plain strings, and escapes the text" do
    render_inline(described_class.new(label: "L", items: { "x" => "<b>one</b>", "y" => "two" }))
    expect(page.native.to_html).not_to include("<b>one</b>")
    render_inline(described_class.new(label: "L", items: %w[one two]))
    expect(page.all("li", visible: :all).map { _1["data-dp-sortable-id"] }).to eq(%w[one two])
  end

  it "speaks French" do
    I18n.with_locale(:fr) { list }
    expect(page.all("button[data-dp-sortable-direction-param='-1']", visible: :all).first["aria-label"]).to eq("Monter Alpha")
    expect(page.find(".dp-sortable", visible: :all)["data-dp-sortable-moved-template-value"]).to include("position")
  end

  it "passes html options through" do
    list(class: "x", id: "s1")
    expect(page).to have_css("div#s1.dp-sortable.x", visible: :all)
  end

  it "rejects invalid input" do
    expect { described_class.new(label: "", items: items) }.to raise_error(ArgumentError, /label/)
    expect { described_class.new(label: "L", items: []) }.to raise_error(ArgumentError, /items/)
    expect { described_class.new(label: "L", items: [ [ "a", "A" ], [ "a", "B" ] ]) }.to raise_error(ArgumentError, /duplicate|unique/)
    expect { described_class.new(label: "L", items: [ [ "a", "" ] ]) }.to raise_error(ArgumentError, /text/)
    expect { described_class.new(label: "L", items: [ [ "", "A" ] ]) }.to raise_error(ArgumentError, /id/)
  end
end
