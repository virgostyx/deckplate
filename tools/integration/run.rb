# Integration test driver (dev only, see bin/integration). Not shipped in the gem.
require "bundler"
require "fileutils"
require "net/http"
require "ferrum"

ROOT = File.expand_path("../..", __dir__)
WORK = File.join(ROOT, "tmp/integration")
RAILS = ENV["RAILS_VERSION"] ? "_#{ENV['RAILS_VERSION']}_" : nil
VARIANTS = { "plain" => { tailwind: false, port: 3811 }, "tailwind" => { tailwind: true, port: 3812 },
             "builtgem" => { tailwind: false, port: 3813, built_gem: true } }.freeze # "builtgem": the built .gem is installed (proves the shipped files are enough)
FAILURES = []

GEM_HOME_DIR = File.join(WORK, "gemhome")

# The built-gem variant looks Deckplate up in an isolated gem directory (plus the usual gems for its dependencies)
def gem_env(built_gem) = built_gem ? { "GEM_PATH" => [ GEM_HOME_DIR, Gem.default_path ].flatten.join(":") } : {}

def sh(dir, command, log, built_gem: false)
  Bundler.with_unbundled_env do
    ok = system({ "BUNDLE_GEMFILE" => nil, "RAILS_ENV" => nil }.merge(gem_env(built_gem)), "#{command} >> #{log} 2>&1", chdir: dir)
    abort "FAILED (see #{log}): #{command}" unless ok
  end
end

def check(variant, name, condition, detail = nil)
  puts "  #{condition ? 'ok  ' : 'FAIL'} #{name}#{detail && !condition ? " (#{detail})" : ''}"
  FAILURES << "#{variant}: #{name}" unless condition
end

def snapshot(dir)
  Dir.glob("{app,config}/**/*", base: dir).select { File.file?(File.join(dir, _1)) }.sort.to_h { [ _1, File.read(File.join(dir, _1)) ] }
end

def build_app(variant, tailwind:, built_gem: false)
  dir = File.join(WORK, variant)
  log = File.join(WORK, "#{variant}.log")
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(WORK)
  FileUtils.rm_f(log)
  puts "== #{variant}: rails new"
  flags = %w[--skip-git --skip-test --skip-system-test --skip-kamal --skip-solid --skip-thruster --skip-jbuilder --skip-docker --skip-ci
             --skip-rubocop --skip-brakeman -a propshaft -j importmap -q]
  flags += %w[--css tailwind] if tailwind
  sh(WORK, "rails #{RAILS} new #{variant} #{flags.join(' ')}", log)
  if built_gem
    puts "== #{variant}: gem build + install into an isolated directory"
    FileUtils.rm_rf(GEM_HOME_DIR)
    sh(ROOT, "gem build deckplate.gemspec --output tmp/integration/deckplate.gem", log)
    sh(ROOT, "gem install --local --ignore-dependencies --no-document --install-dir #{GEM_HOME_DIR} tmp/integration/deckplate.gem", log)
    version = File.read(File.join(ROOT, "lib/deckplate/version.rb"))[/VERSION = "([^"]+)"/, 1]
    File.open(File.join(dir, "Gemfile"), "a") { _1.puts %(\ngem "deckplate", "= #{version}") }
  else
    File.open(File.join(dir, "Gemfile"), "a") { _1.puts %(\ngem "deckplate", path: "#{ROOT}") }
  end
  puts "== #{variant}: bundle install"
  sh(dir, "bundle install --local", log, built_gem: built_gem) if built_gem
  sh(dir, "bundle install", log) unless built_gem
  puts "== #{variant}: rails g deckplate:install (twice)"
  sh(dir, "bin/rails g deckplate:install", log, built_gem: built_gem)
  first = snapshot(dir)
  sh(dir, "bin/rails g deckplate:install", log, built_gem: built_gem)
  check(variant, "installer is idempotent on a real app", snapshot(dir) == first)
  layout = File.read(File.join(dir, "app/views/layouts/application.html.erb"))
  check(variant, "layout is wired (stylesheet, theme attributes, dp-root)", layout.include?('stylesheet_link_tag "deckplate"') && layout.include?("dp_theme_attrs") && layout.include?('class="dp-root"'))
  check(variant, "controllers are registered", File.read(File.join(dir, "app/javascript/controllers/index.js")).include?("registerDeckplate(application)"))
  if tailwind
    css = File.read(File.join(dir, "app/assets/tailwind/application.css"))
    check(variant, "Tailwind source starts with the layer prelude", css.lines.first.strip == "@layer theme, base, dp, components, utilities;")
  end
  FileUtils.mkdir_p(File.join(dir, "app/views/smoke"))
  FileUtils.cp(File.join(ROOT, "tools/integration/smoke_page.html.erb"), File.join(dir, "app/views/smoke/home.html.erb"))
  File.write(File.join(dir, "app/controllers/smoke_controller.rb"), "class SmokeController < ApplicationController\n  def home; end\nend\n")
  sh(dir, "bin/rails g deckplate:gallery", log, built_gem: built_gem)
  routes = File.join(dir, "config/routes.rb")
  File.write(routes, File.read(routes).sub(/^end\s*\z/, %(  root "smoke#home"\nend\n)))
  sh(dir, "bin/rails tailwindcss:build", log) if tailwind
  dir
end

def with_server(dir, port, log, built_gem: false)
  pid = Bundler.with_unbundled_env { Process.spawn({ "BUNDLE_GEMFILE" => nil }.merge(gem_env(built_gem)), "bin/rails server -p #{port} -b 127.0.0.1", chdir: dir, out: log, err: log, pgroup: true) }
  60.times do
    break if (Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/up")).is_a?(Net::HTTPSuccess) rescue false)

    sleep 1
  end
  yield
ensure
  Process.kill("TERM", -Process.getpgid(pid)) rescue nil
  Process.wait(pid) rescue nil
end

def smoke(variant, port, tailwind:)
  puts "== #{variant}: smoke test"
  browser = Ferrum::Browser.new(headless: true, window_size: [ 1280, 900 ], process_timeout: 30)
  errors = []
  browser.on("Runtime.exceptionThrown") { |params| errors << params.dig("exceptionDetails", "exception", "description").to_s }
  browser.network.intercept(false) rescue nil
  browser.go_to("http://127.0.0.1:#{port}/")
  browser.network.wait_for_idle(timeout: 10) rescue nil
  sleep 0.5
  js = ->(code) { browser.evaluate(code) }

  failed = browser.network.traffic.select { _1.response && _1.response.status.to_i >= 400 }.map { "#{_1.response.status} #{_1.url}" }
  check(variant, "no failed requests (CSS, JS, fonts)", failed.empty?, failed.join(", "))
  check(variant, "no JavaScript errors", errors.empty?, errors.join(" | "))
  check(variant, "<html> carries the theme", js.("document.documentElement.dataset.dpTheme") == "classic")
  check(variant, "stylesheet loaded: tokens exist", js.("getComputedStyle(document.documentElement).getPropertyValue('--dp-primary').trim") != "")
  check(variant, "frame rendered with layout", js.("!!document.querySelector('.dp-frame') && document.querySelector('.dp-frame').getBoundingClientRect().height > 100"))
  check(variant, "fonts load from the host's asset pipeline", js.("Array.from(document.fonts).some(function (f) { return f.family.indexOf('Antonio') >= 0 && f.status === 'loaded' })"))
  check(variant, "button is styled (padding and background)", js.("(function(){ var s = getComputedStyle(document.getElementById('plain-button')); return parseFloat(s.paddingLeft) > 4 && s.backgroundColor !== 'rgba(0, 0, 0, 0)' })()"))
  check(variant, "table rendered with a caption and column headers", js.("document.querySelectorAll('table caption, table th').length >= 3"))
  check(variant, "toast container is a live region with the toast", js.("document.querySelector('#dp-toasts[aria-live] .dp-toast') !== null"))

  gallery = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/deckplate"))
  check(variant, "the optional gallery page renders in development", gallery.is_a?(Net::HTTPSuccess) && gallery.body.include?("Colour roles"), gallery.code)

  browser.at_css("#open-modal").click
  sleep 0.4
  check(variant, "Stimulus works: the modal opens on click", js.("!!document.querySelector('dialog[open]')"))
  browser.at_css("#close-modal").click
  sleep 0.4
  check(variant, "and closes", js.("!document.querySelector('dialog[open]')"))

  if tailwind
    plain = js.("getComputedStyle(document.getElementById('plain-button')).backgroundColor")
    utility = js.("getComputedStyle(document.getElementById('utility-button')).backgroundColor")
    bridge = js.("getComputedStyle(document.getElementById('bridge')).backgroundColor")
    check(variant, "a Tailwind utility beats a Deckplate component (ADR 0003)", utility != plain && utility != "rgba(0, 0, 0, 0)", "#{utility} vs #{plain}")
    check(variant, "Deckplate beats Tailwind's preflight reset (button padding kept)", js.("parseFloat(getComputedStyle(document.getElementById('plain-button')).paddingLeft) > 4"))
    check(variant, "the bridge utility bg-dp-primary follows the theme", bridge == plain, "#{bridge} vs #{plain}")
  end
ensure
  browser&.quit
end

wanted = ARGV.empty? ? VARIANTS.keys : ARGV
unknown = wanted - VARIANTS.keys
abort "unknown variant(s): #{unknown.join(', ')} (valid: #{VARIANTS.keys.join(', ')})" if unknown.any?

wanted.each do |variant|
  config = VARIANTS.fetch(variant)
  dir = build_app(variant, tailwind: config[:tailwind], built_gem: config[:built_gem])
  with_server(dir, config[:port], File.join(WORK, "#{variant}.server.log"), built_gem: config[:built_gem]) { smoke(variant, config[:port], tailwind: config[:tailwind]) }
end

puts FAILURES.empty? ? "\nIntegration OK (#{wanted.join(', ')})" : "\nFAILED:\n  #{FAILURES.join("\n  ")}"
exit(FAILURES.empty? ? 0 : 1)
