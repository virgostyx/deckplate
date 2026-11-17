require "tmpdir"
require "fileutils"

# A throwaway host application tree (no Rails boot): just the files the installer reads and patches.
module FixtureApp
  LAYOUT = <<~ERB
    <!DOCTYPE html>
    <html>
      <head>
        <title><%= content_for(:title) || "Host" %></title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <%= csrf_meta_tags %>
        <%= csp_meta_tag %>
        <%= yield :head %>
        <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
        <%= javascript_importmap_tags %>
      </head>
      <body>
        <%= yield %>
      </body>
    </html>
  ERB

  STIMULUS_INDEX = <<~JS
    import { application } from "controllers/application"
    import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
    eagerLoadControllersFrom("controllers", application)
  JS

  def self.build(layout: LAYOUT, importmap: true, stimulus: true, tailwind: false)
    root = Dir.mktmpdir("dp-host")
    write(root, "app/views/layouts/application.html.erb", layout) if layout
    write(root, "config/importmap.rb", %(pin "application"\npin "@hotwired/stimulus", to: "stimulus.min.js"\n)) if importmap
    write(root, "app/javascript/controllers/index.js", STIMULUS_INDEX) if stimulus
    write(root, "app/assets/tailwind/application.css", %(@import "tailwindcss";\n)) if tailwind
    root
  end

  def self.write(root, path, content)
    full = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  def self.read(root, path) = File.read(File.join(root, path))
  def self.exist?(root, path) = File.exist?(File.join(root, path))

  # Every file of the tree with its content, to prove a second run changes nothing
  def self.snapshot(root) = Dir.glob("**/*", base: root).select { File.file?(File.join(root, _1)) }.sort.to_h { [ _1, File.read(File.join(root, _1)) ] }
end
