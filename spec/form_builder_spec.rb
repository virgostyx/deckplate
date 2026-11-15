require "spec_helper"

RSpec.describe Deckplate::FormBuilder, type: :helper do
  let(:ship) { TestShip.new(callsign: "NCC-1", email: "a@b.c", bio: "Hello", tonnage: 12, role: "explorer", shields: true, heading: "b", launched_on: Date.new(2026, 3, 9)) }

  def form(object = ship, **opts, &block)
    html = helper.form_with(model: object, url: "/ships", builder: described_class, **opts, &block)
    Capybara.string(html)
  end

  def invalid_ship
    TestShip.new(callsign: "x", email: "nope", tonnage: 0).tap(&:valid?)
  end

  describe "text-like fields" do
    it "renders a labelled field with the Rails name, id and current value" do
      html = form { |f| f.dp_text_field :callsign }
      expect(html).to have_css("label[for='ship_callsign']", text: "Callsign")
      expect(html).to have_css("input#ship_callsign[name='ship[callsign]'][type='text'][value='NCC-1']")
    end

    it "has email, password, number fields" do
      html = form { |f| safe_join([ f.dp_email_field(:email), f.dp_password_field(:password), f.dp_number_field(:tonnage) ]) }
      expect(html).to have_css("input[type='email'][value='a@b.c']")
      expect(html).to have_css("input[type='password']")
      expect(html).to have_css("input[type='number'][value='12']")
    end

    it "renders a textarea" do
      html = form { |f| f.dp_text_area :bio, rows: 6 }
      expect(html).to have_css("textarea#ship_bio[rows='6']", text: "Hello")
    end
  end

  describe "labels and hints" do
    it "uses the model's human attribute name, a custom label, or an I18n translation" do
      expect(form { |f| f.dp_text_field :callsign, label: "Call sign" }).to have_css("label", text: "Call sign")
      I18n.backend.store_translations(:en, helpers: { label: { ship: { callsign: "Registry code" } } })
      expect(form { |f| f.dp_text_field :callsign }).to have_css("label", text: "Registry code")
    ensure
      I18n.backend.reload!
    end

    it "shows a hint given explicitly or through I18n" do
      expect(form { |f| f.dp_text_field :callsign, hint: "Three letters at least" }).to have_css(".dp-field__hint", text: "Three letters at least")
      I18n.backend.store_translations(:en, helpers: { hint: { ship: { email: "We never share it" } } })
      html = form { |f| f.dp_email_field :email }
      expect(html).to have_css("#ship_email-hint", text: "We never share it")
      expect(html).to have_css("input#ship_email[aria-describedby='ship_email-hint']")
    ensure
      I18n.backend.reload!
    end
  end

  describe "required" do
    it "marks fields that have a presence validator, and only those" do
      html = form { |f| safe_join([ f.dp_text_field(:callsign), f.dp_text_field(:heading) ]) }
      expect(html).to have_css("input#ship_callsign[required]")
      expect(html).not_to have_css("input#ship_heading[required]")
      expect(html).to have_css("label[for='ship_callsign'] .dp-field__required")
    end

    it "can be forced on or off" do
      expect(form { |f| f.dp_text_field :heading, required: true }).to have_css("input#ship_heading[required]")
      expect(form { |f| f.dp_text_field :callsign, required: false }).not_to have_css("input#ship_callsign[required]")
    end
  end

  describe "errors" do
    it "shows the model's errors, flags the control invalid and links it to the message" do
      html = form(invalid_ship) { |f| f.dp_text_field :callsign }
      expect(html).to have_css("input#ship_callsign[aria-invalid='true'][aria-describedby='ship_callsign-error']")
      expect(html).to have_css("#ship_callsign-error", text: "is too short")
      expect(html).to have_css(".dp-field--invalid")
    end

    it "treats only the first invalid field as an alert and autofocuses it" do
      html = form(invalid_ship) { |f| safe_join([ f.dp_text_field(:callsign), f.dp_email_field(:email), f.dp_number_field(:tonnage) ]) }
      expect(html).to have_css("[role='alert']", count: 1)
      expect(html).to have_css("#ship_callsign-error[role='alert']")
      expect(html).to have_css("input[autofocus]", count: 1)
      expect(html).to have_css("input#ship_callsign[autofocus]")
      expect(html).not_to have_css("#ship_email-error[role='alert']")
    end

    it "shows nothing for a valid object and for a new object that was never validated" do
      expect(form { |f| f.dp_text_field :callsign }).not_to have_css(".dp-field__error")
      expect(form(TestShip.new) { |f| f.dp_text_field :callsign }).not_to have_css(".dp-field__error")
    end
  end

  describe "select, check box, radios, range, file, date" do
    it "renders a select with the current value selected" do
      html = form { |f| f.dp_select :role, [ [ "Explorer", "explorer" ], [ "Freighter", "freighter" ] ], include_blank: true }
      expect(html).to have_css("select#ship_role[name='ship[role]']")
      expect(html).to have_css("option[value='explorer'][selected]")
    end

    it "renders a check box with Rails' hidden unchecked value, checked from the boolean attribute" do
      html = form { |f| f.dp_check_box :shields }
      expect(html).to have_css("input[type='hidden'][name='ship[shields]'][value='0']", visible: :all)
      expect(html).to have_css("input[type='checkbox'][name='ship[shields]'][value='1'][checked]", visible: :all)
      expect(form(TestShip.new) { |f| f.dp_check_box :shields }).not_to have_css("input[checked]", visible: :all)
    end

    it "renders radios sharing the field name, with the current value checked" do
      html = form { |f| f.dp_radio_group :heading, [ [ "Alpha", "a" ], [ "Beta", "b" ] ] }
      expect(html).to have_css("fieldset legend", text: "Heading")
      expect(html).to have_css("input[type='radio'][name='ship[heading]']", count: 2, visible: :all)
      expect(html).to have_css("input#ship_heading_b[checked]", visible: :all)
    end

    it "renders a range with its current value" do
      html = form { |f| f.dp_range :power, min: 0, max: 100, unit: "%" }
      expect(html).to have_css("input[type='range'][name='ship[power]'][value='40']", visible: :all)
      expect(html).to have_css("output", text: "40%", visible: :all)
    end

    it "renders a file field" do
      expect(form { |f| f.dp_file_field :photo, accept: "image/*" }).to have_css("input[type='file'][name='ship[photo]'][accept='image/*']")
    end

    it "renders a date field formatted for the browser" do
      expect(form { |f| f.dp_date_field :launched_on }).to have_css("input[type='date'][value='2026-03-09']")
    end
  end

  describe "submit and actions" do
    it "renders a submit button with Rails' default text for the object state" do
      html = form { |f| f.dp_submit }
      expect(html).to have_css("button.dp-button[type='submit']", text: /create ship/i)
      expect(html).not_to have_css("input[type='submit']")
    end

    it "accepts a label and a colour, and groups buttons in actions" do
      html = form { |f| f.dp_actions { f.dp_submit("Launch", color: :success) } }
      expect(html).to have_css(".dp-form-actions button.dp-c-success", text: "Launch")
    end
  end

  describe "nested attributes" do
    it "keeps the builder in fields_for and builds the nested names, ids and errors" do
      ship.crew.each(&:valid?)
      html = form do |f|
        f.fields_for(:crew) { |cf| cf.dp_text_field :name }
      end
      expect(html).to have_css("input#ship_crew_attributes_0_name[name='ship[crew_attributes][0][name]'][value='Ada']")
      expect(html).to have_css("input#ship_crew_attributes_1_name[name='ship[crew_attributes][1][name]'][aria-invalid='true']")
      expect(html).to have_css("#ship_crew_attributes_1_name-error", text: "can't be blank")
    end
  end

  describe "without a model" do
    it "works with a scope and plain values" do
      html = Capybara.string(helper.form_with(scope: :search, url: "/s", builder: described_class) { |f| f.dp_text_field :q, label: "Query", value: "warp" })
      expect(html).to have_css("input#search_q[name='search[q]'][value='warp']")
    end
  end

  describe "configuration" do
    it "can be the default form builder" do
      original = ActionView::Base.default_form_builder
      expect(original).not_to eq(described_class)
      Deckplate::Engine.apply_default_form_builder # form_builder = false: nothing changes
      expect(ActionView::Base.default_form_builder).to eq(original)
      Deckplate.configure { |c| c.form_builder = true }
      Deckplate::Engine.apply_default_form_builder
      expect(ActionView::Base.default_form_builder).to eq(described_class)
    ensure
      ActionView::Base.default_form_builder = original
      Deckplate.reset_configuration!
    end
  end
end
