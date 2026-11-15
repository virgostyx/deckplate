require "capybara/cuprite"

Capybara.register_driver(:dp_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app,
    window_size: [ 1280, 900 ],
    browser_path: ENV["BROWSER_PATH"] || %w[/usr/bin/google-chrome /usr/bin/chromium-browser /usr/bin/chromium].find { File.exist?(_1) },
    browser_options: { "no-sandbox" => nil },
    process_timeout: 20, timeout: 20)
end
Capybara.javascript_driver = :dp_cuprite
Capybara.server = :puma, { Silent: true }
