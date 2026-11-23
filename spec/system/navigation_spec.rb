require "spec_helper"

RSpec.describe "Navigation components behaviour", type: :system, js: true do
  before { driven_by :dp_cuprite }

  describe "Disclosure" do
    it "opens and closes with the mouse and the keyboard" do
      visit "/rails/view_components/disclosure/default"
      expect(page).to have_css("details:not([open])")
      find("summary").click
      expect(page).to have_css("details[open]")
      focus("summary")
      press(:Enter)
      expect(page).to have_css("details:not([open])")
      press(:space)
      expect(page).to have_css("details[open]")
    end
  end

  describe "Tabs (dp-tabs)" do
    before { visit "/rails/view_components/tabs/default" }

    def selected_ids = page.evaluate_script("[...document.querySelectorAll('[role=tab][aria-selected=true]')].map(t => t.id)")
    def visible_panels = page.evaluate_script("[...document.querySelectorAll('[role=tabpanel]')].filter(p => !p.hidden).map(p => p.id)")

    it "selects a tab on click and shows only its panel" do
      find("#crew-tab").click
      expect(selected_ids).to eq([ "crew-tab" ])
      expect(visible_panels).to eq([ "crew-panel" ])
      expect(page).to have_content("Crew: 212 aboard.")
    end

    it "moves with the arrow keys, wrapping at both ends, selecting as it goes (roving tabindex)" do
      focus("#overview-tab")
      press(:Right)
      expect(active_id).to eq("crew-tab")
      expect(selected_ids).to eq([ "crew-tab" ])
      press(:Right, :Right)
      expect(active_id).to eq("overview-tab") # wrapped
      press(:Left)
      expect(active_id).to eq("cargo-tab") # wrapped backwards
      expect(attribute("#cargo-tab", "tabindex")).to eq("0")
      expect(attribute("#overview-tab", "tabindex")).to eq("-1")
    end

    it "jumps to the first and last tab with Home and End" do
      focus("#crew-tab")
      press(:End)
      expect(active_id).to eq("cargo-tab")
      press(:Home)
      expect(active_id).to eq("overview-tab")
      expect(visible_panels).to eq([ "overview-panel" ])
    end

    it "moves focus from the selected tab to its panel with the Tab key" do
      focus("#overview-tab")
      press(:Tab)
      expect(active_id).to eq("overview-panel")
    end

    it "keeps the URL hash in sync when asked, and selects from it on load" do
      visit "/rails/view_components/tabs/with_hash#cargo"
      expect(selected_ids).to eq([ "cargo-tab" ])
      find("#crew-tab").click
      expect(page.evaluate_script("window.location.hash")).to eq("#crew")
    end
  end

  describe "Menu (dp-menu)" do
    before { visit "/rails/view_components/menu/default" }

    def open? = page.evaluate_script("document.querySelector('#ship-menu').matches(':popover-open')")
    def trigger_expanded = attribute("[aria-haspopup='menu']", "aria-expanded")

    it "opens with a click, exposes aria-expanded, and focuses the first item" do
      find("[aria-haspopup='menu']").click
      expect(page).to have_css("#ship-menu:popover-open")
      expect(trigger_expanded).to eq("true")
      wait_until("focus on the first item") { active_text == "Edit" }
    end

    it "opens from the trigger with ArrowDown (first item) and ArrowUp (last item)" do
      focus("[aria-haspopup='menu']")
      press(:Down)
      wait_until("the menu to open on the first item") { open? && active_text == "Edit" }
      press(:Escape)
      wait_until("the menu to close") { !open? }
      focus("[aria-haspopup='menu']")
      press(:Up)
      wait_until("the menu to open on the last item") { open? && active_text == "Delete" }
    end

    it "moves between items with arrows (wrapping), Home and End, keeping a roving tabindex" do
      find("[aria-haspopup='menu']").click
      wait_until("focus on the first item") { active_text == "Edit" }
      press(:Down)
      expect(active_text).to eq("Archive")
      press(:End)
      expect(active_text).to eq("Delete")
      press(:Down)
      expect(active_text).to eq("Edit")
      press(:Up)
      expect(active_text).to eq("Delete")
      press(:Home)
      expect(active_text).to eq("Edit")
      expect(page.evaluate_script("document.querySelectorAll('[role=menuitem][tabindex=\"0\"]').length")).to eq(1)
    end

    it "closes with Escape and returns focus to the trigger" do
      find("[aria-haspopup='menu']").click
      wait_until("the menu to open") { open? && active_text == "Edit" }
      press(:Escape)
      wait_until("the menu to close with aria-expanded=false") { !open? && trigger_expanded == "false" }
      wait_until("focus back on the trigger") { page.evaluate_script("document.activeElement.matches('[aria-haspopup=menu]')") }
    end

    it "closes when Tab leaves the menu and when clicking outside" do
      find("[aria-haspopup='menu']").click
      wait_until("the menu to open") { open? && active_text == "Edit" }
      press(:Tab)
      wait_until("the menu to close on Tab") { !open? }
      find("[aria-haspopup='menu']").click
      wait_until("the menu to reopen") { open? }
      find(".gx-filler").click
      wait_until("the menu to close on outside click") { !open? }
    end

    it "keeps the popover under the trigger and inside the viewport" do
      visit "/rails/view_components/menu/edge"
      find("[aria-haspopup='menu']").click
      rect = page.evaluate_script("(function(){var r=document.querySelector('#edge-menu').getBoundingClientRect(); return [r.left, r.right, window.innerWidth]})()")
      expect(rect[0]).to be >= 0
      expect(rect[1]).to be <= rect[2]
    end
  end

  describe "Tooltip (dp-tooltip)" do
    before { visit "/rails/view_components/tooltip/default" }

    def shown? = page.evaluate_script("document.querySelector('#tip-shields').matches(':popover-open')")

    it "describes the trigger for assistive tech" do
      expect(attribute("button.dp-button", "aria-describedby")).to include("tip-shields")
    end

    it "shows on hover and hides when the pointer leaves" do
      find("button.dp-button").hover
      expect(page).to have_css("#tip-shields:popover-open")
      find(".gx-page").hover
      expect(page).not_to have_css("#tip-shields:popover-open")
    end

    it "shows on keyboard focus and hides on blur and on Escape" do
      press(:Tab)
      expect(shown?).to be(true)
      press(:Escape)
      expect(shown?).to be(false)
      press(:Tab)
      expect(shown?).to be(false) # moved to the link, whose own tooltip is another bubble
      expect(page.evaluate_script("document.querySelector('#tip-link').matches(':popover-open')")).to be(true)
    end
  end

  describe "Tooltip placement and delay" do
    def rect(selector) = page.evaluate_script("(function(){ var r = document.querySelector(#{selector.to_json}).getBoundingClientRect(); return {l: r.left, r: r.right, t: r.top, b: r.bottom} })()").transform_keys(&:to_sym)
    def open_tip(id) = page.execute_script("document.querySelector('#{id} button').focus()")
    def shown?(id) = page.evaluate_script("document.querySelector('#{id}').matches(':popover-open')")

    before { visit "/rails/view_components/tooltip/placements" }

    it "opens above, under, and on either side of the host" do
      { "top" => :t, "bottom" => :b, "start" => :l, "end" => :r }.each_key do |placement|
        open_tip("#host-#{placement}")
        wait_until("tip #{placement}") { shown?("#tip-#{placement}") }
        tip = rect("#tip-#{placement}")
        host = rect("#host-#{placement} .dp-tooltip")
        case placement
        when "top" then expect(tip[:b]).to be <= host[:t]
        when "bottom" then expect(tip[:t]).to be >= host[:b]
        when "start" then expect(tip[:r]).to be <= host[:l] + 1
        when "end" then expect(tip[:l]).to be >= host[:r] - 1
        end
        press(:Escape)
      end
    end

    it "flips to the other side when the bubble would leave the viewport" do
      open_tip("#host-flip")
      wait_until("flipped tip") { shown?("#tip-flip") }
      tip = rect("#tip-flip")
      host = rect("#host-flip .dp-tooltip")
      expect(tip[:t]).to be >= host[:b] # asked for top, but the host sits at the top edge
      expect(tip[:t]).to be >= 0
    end

    it "keeps the bubble inside the viewport" do
      %w[top bottom start end flip].each do |id|
        open_tip("#host-#{id}")
        wait_until("tip #{id}") { shown?("#tip-#{id}") }
        tip = rect("#tip-#{id}")
        width, height = page.evaluate_script("[innerWidth, innerHeight]")
        expect([ tip[:l], tip[:t] ]).to all(be >= 0)
        expect(tip[:r]).to be <= width
        expect(tip[:b]).to be <= height
        press(:Escape)
      end
    end

    it "waits for the delay on hover, cancels when the pointer leaves, but shows at once on keyboard focus" do
      find("#host-slow button").hover
      expect(shown?("#tip-slow")).to be(false)
      wait_until("delayed tip") { shown?("#tip-slow") }
      find(".gx-page").hover
      expect(shown?("#tip-slow")).to be(false)

      find("#host-slow button").hover
      find(".gx-page").hover
      sleep 0.7 # longer than the 500 ms delay
      expect(shown?("#tip-slow")).to be(false)

      open_tip("#host-slow")
      expect(shown?("#tip-slow")).to be(true)
    end
  end

  describe "Modal (dp-modal)" do
    before { visit "/rails/view_components/modal/default" }

    def dialog_open? = page.evaluate_script("document.querySelector('dialog').open")

    it "opens modally from its trigger and moves focus inside" do
      find("button", text: /open dialog/i).click
      expect(dialog_open?).to be(true)
      expect(page.evaluate_script("document.querySelector('dialog').matches(':modal')")).to be(true)
      expect(page.evaluate_script("document.activeElement.closest('dialog') !== null")).to be(true)
      expect(page.evaluate_script("document.documentElement.classList.contains('dp-scroll-lock')")).to be(true)
    end

    # showModal() makes the rest of the page inert. Focus may reach the browser UI (activeElement becomes <body>),
    # but no element of the page behind the dialog may ever receive it.
    it "traps the focus: no element outside the dialog ever gets it, whichever way we Tab" do
      find("button", text: /open dialog/i).click
      outside = "(function(){var a=document.activeElement; return a !== document.body && !a.closest('dialog')})()"
      8.times do
        press(:Tab)
        expect(page.evaluate_script(outside)).to be(false), "focus escaped to #{page.evaluate_script('document.activeElement.outerHTML.slice(0, 80)')}"
      end
      6.times do
        page.driver.browser.keyboard.hold(:Shift) { press(:Tab) }
        expect(page.evaluate_script(outside)).to be(false)
      end
    end

    it "closes with Escape and returns the focus to the trigger, releasing the scroll lock" do
      find("button", text: /open dialog/i).click
      press(:Escape)
      wait_until("the dialog to close") { !dialog_open? }
      wait_until("focus back on the trigger") { active_text =~ /open dialog/i }
      wait_until("the scroll lock to be released") { !page.evaluate_script("document.documentElement.classList.contains('dp-scroll-lock')") }
    end

    it "closes with the close button, an action button and a click on the backdrop" do
      find("button", text: /open dialog/i).click
      find(".dp-modal__close").click
      expect(dialog_open?).to be(false)
      find("button", text: /open dialog/i).click
      find(".dp-modal__actions button", text: /cancel/i).click
      expect(dialog_open?).to be(false)
      find("button", text: /open dialog/i).click
      page.driver.browser.mouse.click(x: 5, y: 5) # outside the panel: on the backdrop
      expect(dialog_open?).to be(false)
    end

    it "stays open when the click lands inside the panel" do
      find("button", text: /open dialog/i).click
      find(".dp-modal__body").click
      expect(dialog_open?).to be(true)
    end

    it "makes the page behind it inert" do
      find("button", text: /open dialog/i).click
      expect(page.evaluate_script("document.elementFromPoint(5, 5).tagName")).to eq("DIALOG")
    end

    it "opens by itself when open: true" do
      visit "/rails/view_components/modal/open"
      expect(page).to have_css("dialog[open]")
    end

    it "makes a scrolling body keyboard-focusable (and only then)" do
      visit "/rails/view_components/modal/long"
      expect(attribute(".dp-modal__body", "tabindex")).to eq("0")
      visit "/rails/view_components/modal/default"
      find("button", text: /open dialog/i).click
      expect(attribute(".dp-modal__body", "tabindex")).to be_nil
    end

    it "follows the content: focusable once it grows past the dialog after opening, and not any more when it shrinks (G-8)" do
      visit "/rails/view_components/modal/default"
      find("button", text: /open dialog/i).click
      expect(attribute(".dp-modal__body", "tabindex")).to be_nil
      page.execute_script("document.querySelector('.dp-modal__body').insertAdjacentHTML('beforeend', '<div id=\"late\" style=\"block-size: 3000px\">late content</div>')")
      expect(page).to have_css(".dp-modal__body[tabindex='0']")
      page.execute_script("document.getElementById('late').remove()")
      expect(page).to have_no_css(".dp-modal__body[tabindex]")
    end

    it "scrolls its body, not the page, when the content is long" do
      visit "/rails/view_components/modal/long"
      body = page.evaluate_script("(function(){var b=document.querySelector('.dp-modal__body'); return [b.scrollHeight, b.clientHeight]})()")
      expect(body[0]).to be > body[1]
      panel_bottom = page.evaluate_script("document.querySelector('.dp-modal__panel').getBoundingClientRect().bottom")
      expect(panel_bottom).to be <= page.evaluate_script("window.innerHeight")
    end
  end

  describe "Modal with a Turbo form" do
    before do
      visit "/rails/view_components/modal/form"
      find("button", text: /rename/i).click
    end

    it "closes after a successful submission (303)" do
      click_button "Save"
      expect(page).to have_no_css("dialog[open]")
    end

    it "stays open when the server answers 422" do
      click_button "Fail (422)"
      expect(page).to have_css("dialog[open]")
    end
  end

  describe "Pagination" do
    it "navigates through Turbo to the clicked page" do
      visit "/rails/view_components/pagination/default"
      expect(page).to have_css("[aria-current='page']", text: "3")
      find("a[aria-label='Page 4']").click
      expect(page).to have_current_path(%r{/ships\?page=4})
    end
  end
end
