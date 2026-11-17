require "spec_helper"

RSpec.describe Deckplate::Forms::KeypadComponent, type: :component do
  def build(**opts) = described_class.new(name: "ship[callsign]", label: "Callsign", **opts)
  let(:control_css) { "input.dp-keypad__input" }

  it_behaves_like "a form control"

  describe "the field" do
    it "is a real input inside the form field, so typing and submitting work natively" do
      render_inline(build)
      expect(page).to have_css(".dp-field .dp-keypad input.dp-input.dp-keypad__input[type='text'][inputmode='numeric'][autocomplete='off']", visible: :all)
    end

    it "shows the current value" do
      render_inline(build(value: "12"))
      expect(page.find("input.dp-keypad__input")[:value]).to eq("12")
    end

    it "accepts only digits by pattern, any count without a length" do
      render_inline(build)
      expect(page.find("input.dp-keypad__input")[:pattern]).to eq("[0-9]*")
      expect(page.find("input.dp-keypad__input")[:maxlength]).to be_nil
    end

    it "fixes the number of digits with length:" do
      render_inline(build(length: 4))
      input = page.find("input.dp-keypad__input")
      expect(input[:maxlength]).to eq("4")
      expect(input[:pattern]).to eq("[0-9]{4}")
    end

    it "masks the digits and never writes the value back into the page" do
      render_inline(build(masked: true, value: "9876"))
      input = page.find("input.dp-keypad__input", visible: :all)
      expect(input[:type]).to eq("password")
      expect(input[:value]).to be_nil
      expect(page.native.to_html).not_to include("9876")
    end
  end

  describe "the pad" do
    it "is a labelled group of twelve real buttons: 1-9, clear, 0, delete" do
      render_inline(build)
      expect(page).to have_css(".dp-keypad__pad[role='group'][aria-label='Keypad'] button[type='button']", count: 12)
      labels = page.all(".dp-keypad__pad button").map { _1["aria-label"] || _1.text.strip }
      expect(labels).to eq(%w[1 2 3 4 5 6 7 8 9] + [ "Clear", "0", "Delete last digit" ])
    end

    it "wires each digit to the controller with its value" do
      render_inline(build)
      digits = page.all(".dp-keypad__pad button[data-dp-keypad-digit-param]")
      expect(digits.map { _1["data-dp-keypad-digit-param"] }).to eq(%w[1 2 3 4 5 6 7 8 9 0])
      expect(digits.map { _1["data-action"] }.uniq).to eq([ "dp-keypad#press" ])
      expect(page).to have_css("button[data-action='dp-keypad#clear']")
      expect(page).to have_css("button[data-action='dp-keypad#backspace']")
    end

    it "gives the keys their colour, and the clear and delete keys a quieter one" do
      render_inline(build(color: :secondary))
      expect(page).to have_css(".dp-keypad__pad button.dp-c-secondary", count: 10)
      expect(page).to have_css(".dp-keypad__pad button.dp-c-muted", count: 2)
    end

    it "disables the input and every key together" do
      render_inline(build(disabled: true))
      expect(page.find("input.dp-keypad__input", visible: :all)[:disabled]).not_to be_nil
      expect(page.all(".dp-keypad__pad button").map { _1[:disabled] }.compact.size).to eq(12)
    end
  end

  describe "announcements" do
    it "has a polite live region for the number of digits, empty until a key is pressed" do
      render_inline(build)
      status = page.find(".dp-keypad [aria-live='polite'][data-dp-keypad-target='status']", visible: :all)
      expect(status[:class]).to include("dp-sr-only")
      expect(status.text).to eq("")
      expect(page.find(".dp-keypad", visible: :all)["data-dp-keypad-status-template-value"]).to eq("Digits entered: %{count}")
    end

    it "speaks French" do
      I18n.with_locale(:fr) { render_inline(build) }
      expect(page).to have_css(".dp-keypad__pad[aria-label='Pavé numérique']")
      expect(page).to have_css("button[aria-label='Effacer tout']")
      expect(page).to have_css("button[aria-label='Supprimer le dernier chiffre']")
      expect(page.find(".dp-keypad", visible: :all)["data-dp-keypad-status-template-value"]).to eq("Chiffres saisis : %{count}")
    end
  end

  describe "submit key" do
    it "has none by default" do
      render_inline(build)
      expect(page).not_to have_css("button[type='submit']")
    end

    it "adds a submit button with the given label" do
      render_inline(build(submit: "Unlock"))
      expect(page).to have_css("button[type='submit']", text: "Unlock")
    end

    it "is disabled with the rest when the field is" do
      render_inline(build(submit: "Unlock", disabled: true))
      expect(page.find("button[type='submit']", visible: :all)[:disabled]).not_to be_nil
    end
  end

  describe "validation" do
    it "rejects a length that is not between 1 and 12" do
      [ 0, 13, -1, "4", 2.5 ].each { |bad| expect { build(length: bad) }.to raise_error(ArgumentError, /length/) }
    end

    it "rejects a blank submit label" do
      expect { build(submit: " ") }.to raise_error(ArgumentError, /submit/)
    end

    it "keeps the base rules: a name and a label are required" do
      expect { described_class.new(name: "", label: "x") }.to raise_error(ArgumentError, /name/)
      expect { described_class.new(name: "n", label: "") }.to raise_error(ArgumentError, /label/)
    end
  end

  it "passes html options to the input" do
    render_inline(build(class: "x", data: { k: 1 }, placeholder: "----"))
    input = page.find("input.dp-keypad__input", visible: :all)
    expect(input[:class]).to include("x")
    expect(input["data-k"]).to eq("1")
    expect(input[:placeholder]).to eq("----")
  end
end
