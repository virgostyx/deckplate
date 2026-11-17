require "rails/generators"

module Deckplate
  module Generators
    # rails g deckplate:install
    # Idempotent: every step checks what is already there. It patches a file only when the change is unambiguous, otherwise it prints
    # the exact lines to add (a wrong guess in a host layout is worse than a printed instruction).
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Creates the initializer, wires the layout, registers the Stimulus controllers and prepares Tailwind if present."

      LAYER_PRELUDE = "@layer theme, base, dp, components, utilities;".freeze
      LAYOUT = "app/views/layouts/application.html.erb".freeze
      STIMULUS_INDEX = "app/javascript/controllers/index.js".freeze
      TAILWIND_SOURCE = "app/assets/tailwind/application.css".freeze
      BRIDGE_FILE = "app/assets/tailwind/deckplate-bridge.css".freeze
      BRIDGE_IMPORT = '@import "./deckplate-bridge.css";'.freeze
      TAILWIND_IMPORT = /^@import\s+["']tailwindcss["'];/

      def create_initializer
        if File.exist?(File.join(destination_root, "config/initializers/deckplate.rb"))
          say_status :exist, "config/initializers/deckplate.rb (already there, left as is)", :blue
        else
          template "initializer.rb.tt", "config/initializers/deckplate.rb"
        end
      end

      def wire_layout
        path = File.join(destination_root, LAYOUT)
        return manual(:layout, "no #{LAYOUT} found") unless File.exist?(path)

        content = File.read(path)
        updated = patch_head(content)
        updated = patch_html_tag(updated)
        updated = patch_body_tag(updated)
        if updated == content
          say_status :identical, "#{LAYOUT} (already wired)", :blue
        else
          File.write(path, updated)
          say_status :update, LAYOUT, :green
        end
      end

      def register_stimulus_controllers
        path = File.join(destination_root, STIMULUS_INDEX)
        importmap = File.exist?(File.join(destination_root, "config/importmap.rb"))
        return manual(:stimulus, importmap ? "no #{STIMULUS_INDEX} found" : "no importmap found (bundler setups need the JS package; see the installation guide)") unless importmap && File.exist?(path)

        content = File.read(path)
        if content.include?("registerDeckplate")
          say_status :identical, "#{STIMULUS_INDEX} (already registered)", :blue
        else
          File.write(path, content.sub(/\n*\z/, "\n") + %(import { registerDeckplate } from "deckplate"\nregisterDeckplate(application)\n))
          say_status :update, STIMULUS_INDEX, :green
        end
      end

      def prepare_tailwind
        path = File.join(destination_root, TAILWIND_SOURCE)
        return unless File.exist?(path)

        content = File.read(path)
        content = "#{LAYER_PRELUDE}\n#{content}" unless content.include?(LAYER_PRELUDE)
        unless content.include?(BRIDGE_IMPORT)
          if content.match?(TAILWIND_IMPORT)
            content = content.sub(TAILWIND_IMPORT) { "#{$&}\n#{BRIDGE_IMPORT}" }
          else
            manual_steps << [ :tailwind, "no @import \"tailwindcss\" found", [ BRIDGE_IMPORT, "(after your Tailwind import, in #{TAILWIND_SOURCE})" ] ]
            say_status :manual, "no @import \"tailwindcss\" in #{TAILWIND_SOURCE}", :yellow
          end
        end
        if File.read(path) == content
          say_status :identical, "#{TAILWIND_SOURCE} (prelude and bridge import already there)", :blue
        else
          File.write(path, content)
          say_status :update, "#{TAILWIND_SOURCE} (layer prelude first, ADR 0003; bridge import, ADR 0016)", :green
        end
        copy_file "tailwind_bridge.css", BRIDGE_FILE, skip: true
      end

      def print_summary
        say "\nDeckplate installed (re-running is safe).", :green
        say <<~TEXT

          Next steps:
            * put <%= dp_toast_container %> once in your layout (inside the body) to receive toasts;
            * wrap pages in components, for example render Deckplate::Layout::FrameComponent.new(...);
            * choose themes and options in config/initializers/deckplate.rb.
          Documentation: see the README (installation, theming, stylesheets, accessibility).
        TEXT
        manual_steps.each { |name, reason, lines| say "\nTo do by hand (#{name}: #{reason}):\n#{lines.map { "  #{_1}" }.join("\n")}", :yellow }
      end

      private

      def manual_steps = (@manual_steps ||= [])

      INSTRUCTIONS = {
        layout: [ "in the <head>: <%= dp_font_tags %> then <%= stylesheet_link_tag \"deckplate\" %> (before your own stylesheet),",
                  "on <html>: <%= tag.attributes(dp_theme_attrs) %>   on <body>: class=\"dp-root\"" ],
        stimulus: [ "import { registerDeckplate } from \"deckplate\"", "registerDeckplate(application)   // after your Stimulus application is created" ]
      }.freeze

      def manual(name, reason)
        manual_steps << [ name, reason, INSTRUCTIONS.fetch(name) ]
        say_status :manual, reason, :yellow
      end

      # fonts + stylesheet, before the host's first stylesheet tag (or at the end of <head>)
      def patch_head(content)
        return content if content.include?('stylesheet_link_tag "deckplate"')

        block = "<%= dp_font_tags %>\n<%= stylesheet_link_tag \"deckplate\" %>"
        if (match = content.match(/^([ \t]*)<%=\s*stylesheet_link_tag/))
          content.sub(match[0], "#{indent(block, match[1])}\n#{match[0]}")
        elsif (match = content.match(%r{^([ \t]*)</head>}))
          content.sub(match[0], "#{indent(block, match[1] + '  ')}\n#{match[0]}")
        else
          note_manual(:layout, "no <head> found")
          content
        end
      end

      def patch_html_tag(content)
        return content if content.include?("dp_theme_attrs")

        if content.match?(/<html>/)
          content.sub("<html>", "<html <%= tag.attributes(dp_theme_attrs) %>>")
        elsif (match = content.match(/<html( [^<>]*)>/)) # plain attributes only
          content.sub(match[0], "<html#{match[1]} <%= tag.attributes(dp_theme_attrs) %>>")
        else
          note_manual(:layout, "<html> holds ERB or is missing")
          content
        end
      end

      def patch_body_tag(content)
        return content if content.match?(/<body[^>]*\bdp-root\b/)

        if content.match?(/<body>/)
          content.sub("<body>", '<body class="dp-root">')
        elsif (match = content.match(/<body([^<>]*)\bclass="([^"<>]*)"([^<>]*)>/))
          content.sub(match[0], %(<body#{match[1]}class="dp-root #{match[2]}"#{match[3]}>))
        else
          note_manual(:layout, "<body> holds ERB or other attributes")
          content
        end
      end

      def note_manual(name, reason)
        manual_steps << [ name, reason, INSTRUCTIONS.fetch(name) ] unless manual_steps.any? { _1[0] == name }
        say_status :manual, reason, :yellow
      end

      def indent(text, prefix) = text.lines.map { "#{prefix}#{_1}" }.join
    end
  end
end
