# Shared helpers for system specs: real keyboard input and focus inspection (Capybara's send_keys clicks first).
module SystemHelpers
  def focus(selector) = page.execute_script("document.querySelector(#{selector.to_json}).focus()")
  def press(*keys) = keys.each { |k| page.driver.browser.keyboard.type(k) }
  def active_id = page.evaluate_script("document.activeElement && document.activeElement.id")
  def active_matches?(selector) = page.evaluate_script("document.activeElement.matches(#{selector.to_json})")
  def active_text = page.evaluate_script("document.activeElement.textContent.trim()")

  # Popover `toggle` events and focus changes are asynchronous: wait for a state instead of reading it right away.
  def wait_until(description, timeout: 3)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until (result = yield)
      raise "Timed out after #{timeout}s waiting for #{description}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.05
    end
    result
  end

  def attribute(selector, name) = page.evaluate_script("document.querySelector(#{selector.to_json}).getAttribute(#{name.to_json})")
end

RSpec.configure { |c| c.include SystemHelpers, type: :system }
