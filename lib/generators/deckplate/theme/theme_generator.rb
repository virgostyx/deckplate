require "rails/generators"

module Deckplate
  module Generators
    # rails g deckplate:theme ocean
    # Starts a theme from the classic colour mapping so every required token is defined; the host then edits the values.
    class ThemeGenerator < Rails::Generators::NamedBase
      desc "Creates app/assets/stylesheets/deckplate-theme-NAME.css, adds NAME to config.themes and links the stylesheet."

      PRELUDE = <<~CSS.freeze
        @layer theme, base, dp, components, utilities;
        @layer dp.tokens, dp.base, dp.shapes, dp.layout, dp.components, dp.states;
      CSS
      CLASSIC = Deckplate::Engine.root.join("app/assets/stylesheets/deckplate/themes/classic.css")
      LAYOUT = "app/views/layouts/application.html.erb".freeze
      INITIALIZER = "config/initializers/deckplate.rb".freeze
      THEMES_LINE = /^(\s*c\.themes\s*=\s*%i\[)([^\]]*)(\])/

      def check_name
        raise Thor::Error, "invalid theme name #{name.inspect} (lowercase letters, digits and hyphens)" unless name.match?(Deckplate::Configuration::THEME_NAME)
        raise Thor::Error, "#{name} is a built-in theme; pick another name" if Deckplate::Configuration::BUILT_IN_THEMES.include?(name.to_sym)
      end

      def create_stylesheet
        if File.exist?(File.join(destination_root, stylesheet_path))
          say_status :exist, "#{stylesheet_path} (already there, left as is)", :blue
        else
          create_file stylesheet_path, "#{PRELUDE}#{classic_copy}"
        end
      end

      def register_theme
        path = File.join(destination_root, INITIALIZER)
        content = File.exist?(path) ? File.read(path) : ""
        if content.match?(THEMES_LINE)
          list = content[THEMES_LINE, 2].split
          return say_status :identical, "#{INITIALIZER} (#{name} already listed)", :blue if list.include?(name)

          File.write(path, content.sub(THEMES_LINE) { "#{$1}#{[ *list, name ].join(' ')}#{$3}" })
          say_status :update, INITIALIZER, :green
        else
          say "To do by hand: add :#{name} to config.themes in #{INITIALIZER} (Deckplate.configure { |c| c.themes = [..., :#{name}] }).", :yellow
        end
      end

      def link_stylesheet
        path = File.join(destination_root, LAYOUT)
        tag = %(stylesheet_link_tag "#{sheet_name}")
        return say("To do by hand: <%= #{tag} %> after Deckplate's stylesheet in your layout.", :yellow) unless File.exist?(path)

        content = File.read(path)
        return say_status(:identical, "#{LAYOUT} (#{sheet_name} already linked)", :blue) if content.include?(tag)

        if (match = content.match(/^([ \t]*)<%=\s*stylesheet_link_tag "deckplate"[^%]*%>\n/))
          File.write(path, content.sub(match[0], "#{match[0]}#{match[1]}<%= #{tag} %>\n"))
          say_status :update, LAYOUT, :green
        else
          say "To do by hand: <%= #{tag} %> right after <%= stylesheet_link_tag \"deckplate\" %> in your layout.", :yellow
        end
      end

      private

      def sheet_name = "deckplate-theme-#{name}"
      def stylesheet_path = "app/assets/stylesheets/#{sheet_name}.css"

      def classic_copy
        css = File.read(CLASSIC).sub(/\A\/\*.*?\*\/\n/, "/* Theme #{name}: starts as a copy of classic. Edit the values, then run the contrast spec pattern on your pairs (see the theming guide). */\n")
        css.sub(/:root,\s*\[data-dp-theme="classic"\]/, %([data-dp-theme="#{name}"]))
      end
    end
  end
end
