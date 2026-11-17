require "spec_helper"

RSpec.describe "Keypad (dp-keypad)", type: :system, js: true do
  before do
    driven_by :dp_cuprite
    visit "/rails/view_components/keypad/default"
  end

  def value = page.evaluate_script("document.getElementById('pin').value")
  def key(label) = find(".dp-keypad__pad button", text: label, exact_text: true)
  def press_keys(*labels) = labels.each { key(_1).click }
  def status = page.evaluate_script("document.querySelector('[data-dp-keypad-target=status]').textContent")

  describe "the pad fills the input" do
    it "appends the digit of each key" do
      press_keys("1", "2", "3")
      expect(value).to eq("123")
    end

    it "ignores keys beyond the length (maxlength)" do
      press_keys("1", "2", "3", "4", "5", "6")
      expect(value).to eq("1234")
    end

    it "deletes the last digit with the delete key and everything with clear" do
      press_keys("1", "2", "3")
      find("button[aria-label='Delete last digit']").click
      expect(value).to eq("12")
      find("button[aria-label='Clear']").click
      expect(value).to eq("")
    end

    it "does nothing when there is nothing to delete" do
      find("button[aria-label='Delete last digit']").click
      expect(value).to eq("")
    end

    it "keeps the focus on the key that was pressed (a keyboard user can press the next one)" do
      key("5").click
      expect(page.evaluate_script("document.activeElement.textContent.trim()")).to eq("5")
    end

    it "works with the keyboard: Enter or Space on a focused key" do
      focus(".dp-keypad__pad button[data-dp-keypad-digit-param='7']")
      press(:Enter)
      press(:space)
      expect(value).to eq("77")
    end

    it "fires an input event for each change, so form logic (dp-field, host scripts) sees it" do
      page.execute_script("window.__inputs = 0; document.getElementById('pin').addEventListener('input', function () { window.__inputs++ })")
      press_keys("1", "2")
      find("button[aria-label='Delete last digit']").click
      find("button[aria-label='Clear']").click
      expect(page.evaluate_script("window.__inputs")).to eq(4)
    end
  end

  describe "the physical keyboard" do
    it "types digits into the field" do
      find("#pin").click
      page.driver.browser.keyboard.type("4821")
      expect(value).to eq("4821")
    end

    it "drops anything that is not a digit" do
      find("#pin").click
      page.driver.browser.keyboard.type("1a-2 b3")
      expect(value).to eq("123")
    end

    it "keeps the typed digits when the pad is used next" do
      find("#pin").click
      page.driver.browser.keyboard.type("12")
      press_keys("3")
      expect(value).to eq("123")
    end

    it "submits the form on Enter, with the value" do
      press_keys("9", "0", "9", "0")
      find("#pin").click
      press(:Enter)
      expect(page).to have_current_path("/up?pin=9090")
    end

    it "submits with the submit key" do
      press_keys("1", "1", "2", "2")
      click_button "Unlock"
      expect(page).to have_current_path("/up?pin=1122")
    end
  end

  describe "announcements" do
    it "tells how many digits there are, as the user presses keys" do
      expect(status).to eq("")
      press_keys("1", "2")
      expect(status).to eq("Digits entered: 2")
      find("button[aria-label='Clear']").click
      expect(status).to eq("Digits entered: 0")
    end

    it "never reads the digits out (a masked code stays secret)" do
      visit "/rails/view_components/keypad/states"
      press_masked = ->(digit) { page.execute_script("document.getElementById('masked').closest('.dp-keypad').querySelector('button[data-dp-keypad-digit-param=\"#{digit}\"]').click()") }
      press_masked.call("7")
      press_masked.call("3")
      text = page.evaluate_script("document.getElementById('masked').closest('.dp-keypad').querySelector('[data-dp-keypad-target=status]').textContent")
      expect(text).to eq("Digits entered: 2")
      expect(text).not_to match(/[73]/)
      expect(page.evaluate_script("document.getElementById('masked').type")).to eq("password")
    end
  end

  describe "Turbo morph (dp-field keeps what the user entered)" do
    it "keeps a code entered with the pad when the page refreshes in place" do
      press_keys("3", "1", "4")
      page.execute_script("Turbo.visit(window.location.href, { action: 'replace' })")
      sleep 0.7
      expect(value).to eq("314")
    end
  end

  describe "Turbo Stream" do
    it "works in a keypad that arrives in a stream response (the controller connects to inserted markup)" do
      html = page.evaluate_script("document.querySelector('#code-form .dp-field').outerHTML").gsub('id="pin"', 'id="pin2"').gsub('pin-hint', 'pin2-hint').gsub('for="pin"', 'for="pin2"')
      page.execute_script("Turbo.renderStreamMessage(#{%(<turbo-stream action="append" target="code-form"><template>#{html}</template></turbo-stream>).to_json})")
      expect(page).to have_css("#pin2")
      page.execute_script("document.getElementById('pin2').closest('.dp-keypad').querySelector('button[data-dp-keypad-digit-param=\"8\"]').click()")
      expect(page.evaluate_script("document.getElementById('pin2').value")).to eq("8")
      expect(page.evaluate_script("document.getElementById('pin').value")).to eq("") # the first keypad is untouched
    end
  end

  describe "states" do
    before { visit "/rails/view_components/keypad/states" }

    it "shows the preset value and lets the pad continue from it" do
      page.execute_script("document.querySelectorAll('.dp-keypad')[1].querySelector('button[data-dp-keypad-digit-param=\"1\"]').click()")
      expect(page.evaluate_script("document.getElementById('free').value")).to eq("421")
    end

    it "does not react when disabled" do
      expect(page.evaluate_script("document.getElementById('disabled').disabled")).to be(true)
      expect(page.evaluate_script("Array.from(document.querySelectorAll('.dp-keypad')[3].querySelectorAll('button')).every(function (b) { return b.disabled })")).to be(true)
    end
  end
end
