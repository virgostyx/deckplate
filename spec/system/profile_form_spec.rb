require "spec_helper"

# The dummy app's profile form: Deckplate::FormBuilder end to end with Turbo (422 re-render, 303 redirect), keyboard only.
RSpec.describe "Profile form", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    Profile.reset!
  end

  def type(text) = page.driver.browser.keyboard.type(text)
  def mark_page = page.execute_script("window.__sameDocument = true")
  def same_document? = page.evaluate_script("window.__sameDocument === true")

  # Tab order of the new form: callsign, email, bio, role, shields, contact (radio group: one stop), clearance, birthday, submit
  def fill_everything_with_the_keyboard
    find("#profile_callsign").click # the only mouse action: put the focus at the start of the form
    type("NCC-1701")
    press(:Tab); type("kirk@example.org")
    press(:Tab); type("Captain of the Aurora")
    press(:Tab); type("Explorer")                  # a select: typing selects the matching option
    press(:Tab); press(:space)                     # check box
    press(:Tab); press(:Down)                      # radio group: arrows move and check (comms -> courier)
    press(:Tab); press(:Right, :Right)             # range: 20 -> 22 (step 5 gives 25)
    press(:Tab); type("03032000")                  # native date control: day and month are both 03, so the locale order does not matter
    press(:Tab, :Tab)                              # ... then Chrome's calendar button, then the submit button
  end

  it "can be completed with the keyboard alone, and ends on the profile page with a confirmation" do
    visit "/profile/new"
    mark_page
    fill_everything_with_the_keyboard
    expect(active_matches?("button[type='submit']")).to be(true)
    press(:Enter)
    expect(page).to have_current_path("/profile")
    expect(page).to have_css("[role='status']", text: "Profile created.")
    expect(page).to have_css("[data-attr='callsign']", text: "NCC-1701")
    expect(page).to have_css("[data-attr='role']", text: "explorer")
    expect(page).to have_css("[data-attr='contact']", text: "courier")
    expect(page).to have_css("[data-attr='shields']", text: "Yes")
    expect(page).to have_css("[data-attr='birthday']", text: "2000-03-03")
    expect(same_document?).to be(true) # Turbo, not a full page load
  end

  describe "server-side validation (422)" do
    before do
      visit "/profile/new"
      mark_page
      find("#profile_callsign").set("x")
      find("#profile_bio").set("Kept on error")
      click_button "Create Profile"
    end

    it "re-renders the form in place with the errors, keeping what was typed" do
      expect(page).to have_css(".dp-field--invalid", minimum: 3)
      expect(page).to have_css("#profile_callsign-error", text: "is too short")
      expect(page).to have_css("#profile_email-error", text: "can't be blank")
      expect(page.find("#profile_bio").value).to eq("Kept on error")
      expect(page.find("#profile_callsign").value).to eq("x")
      expect(same_document?).to be(true)
    end

    it "links every invalid control to its error and flags it invalid" do
      %w[callsign email role birthday].each do |field|
        expect(attribute("#profile_#{field}", "aria-invalid")).to eq("true")
        expect(attribute("#profile_#{field}", "aria-describedby")).to include("profile_#{field}-error")
      end
      expect(attribute("#profile_bio", "aria-invalid")).to be_nil # valid fields stay clean
    end

    it "announces only the first error as an alert and moves the focus to that field" do
      expect(page).to have_css("[role='alert']", count: 1)
      expect(page).to have_css("#profile_callsign-error[role='alert']")
      wait_until("focus on the first invalid field") { active_id == "profile_callsign" }
    end

    it "shows no error summary leak into valid fields and marks required fields" do
      expect(page).to have_css("label[for='profile_callsign'] .dp-field__required")
      expect(page).not_to have_css("label[for='profile_bio'] .dp-field__required")
    end

    it "lets the user correct the field and submit successfully" do
      find("#profile_callsign").set("NCC-1701")
      find("#profile_email").set("a@b.c")
      find("#profile_role").select("Medic")
      find("#profile_birthday").set(Date.new(2000, 1, 2))
      click_button "Create Profile"
      expect(page).to have_current_path("/profile")
      expect(page).to have_css("[data-attr='role']", text: "medic")
    end
  end

  it "edits an existing profile: prefilled fields, 422 on a bad update, then a confirmed update" do
    Profile.stored = Profile.new(callsign: "NCC-1", email: "a@b.c", role: "medic", contact: "none", clearance: 55, birthday: Date.new(1999, 5, 6), shields: true)
    visit "/profile/edit"
    expect(page.find("#profile_callsign").value).to eq("NCC-1")
    expect(page.find("#profile_role").value).to eq("medic")
    expect(page).to have_checked_field("profile_shields", visible: :all)
    expect(page).to have_checked_field("profile_contact_none", visible: :all)
    expect(page.find("#profile_birthday").value).to eq("1999-05-06")
    expect(page.find("input[type='range']", visible: :all).value).to eq("55")
    find("#profile_callsign").set("")
    click_button "Update Profile"
    expect(page).to have_css("#profile_callsign-error", text: "can't be blank")
    find("#profile_callsign").set("NCC-2")
    click_button "Update Profile"
    expect(page).to have_css("[role='status']", text: "Profile updated.")
    expect(page).to have_css("[data-attr='callsign']", text: "NCC-2")
  end

  describe "Turbo morph refresh (the page re-renders in place, e.g. after a broadcast)" do
    before { visit "/profile/new" }

    def morph_refresh
      page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
      sleep 0.6
    end

    it "keeps what the user typed in every kind of field" do
      find("#profile_callsign").set("Typed callsign")
      find("#profile_bio").set("Typed bio")
      find("#profile_role").select("Medic")
      find("label[for='profile_shields']").click
      find("label[for='profile_contact_courier']").click
      find("#profile_email").click # focus somewhere else: the typed fields are not the active element
      morph_refresh
      expect(page.find("#profile_callsign").value).to eq("Typed callsign")
      expect(page.find("#profile_bio").value).to eq("Typed bio")
      expect(page.find("#profile_role").value).to eq("medic")
      expect(page).to have_checked_field("profile_shields", visible: :all)
      expect(page).to have_checked_field("profile_contact_courier", visible: :all)
    end

    it "keeps the slider value and its readout" do
      focus("input[type='range']")
      press(:Right, :Right)
      find("#profile_callsign").click
      morph_refresh
      expect(page.find("input[type='range']", visible: :all).value).to eq("30")
      expect(page).to have_css("output", text: "30%")
    end
  end

  describe "accessibility (axe) in every theme" do
    Deckplate::Configuration::BUILT_IN_THEMES.each do |theme|
      it "has no violations in #{theme}, valid and invalid" do
        page.driver.browser.cookies.set(name: "dp_theme", value: theme.to_s, domain: "127.0.0.1", path: "/")
        visit "/profile/new"
        expect(page).to have_css("html[data-dp-theme='#{theme}']")
        expect(axe_violations).to be_empty, "new (#{theme}):\n#{axe_report(axe_violations)}"
        click_button "Create Profile"
        expect(page).to have_css(".dp-field--invalid")
        expect(axe_violations).to be_empty, "invalid (#{theme}):\n#{axe_report(axe_violations)}"
      end
    end
  end
end
