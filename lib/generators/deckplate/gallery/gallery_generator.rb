require "rails/generators"

module Deckplate
  module Generators
    # rails g deckplate:gallery
    # Optional. Adds a development-only page that shows the components in the host's own layout and themes. Mounts nothing by default.
    class GalleryGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Adds a development-only gallery page at /deckplate."

      ROUTE = 'get "deckplate", to: "deckplate_gallery#show" if Rails.env.development?'.freeze
      ROUTES_FILE = "config/routes.rb".freeze

      def create_controller
        keep_existing "app/controllers/deckplate_gallery_controller.rb", "controller.rb"
      end

      def create_view
        keep_existing "app/views/deckplate_gallery/show.html.erb", "show.html.erb"
      end

      def add_route
        path = File.join(destination_root, ROUTES_FILE)
        return say("To do by hand: add #{ROUTE} to your routes.", :yellow) unless File.exist?(path)

        content = File.read(path)
        return say_status(:identical, "#{ROUTES_FILE} (gallery route already there)", :blue) if content.include?(ROUTE)

        updated = content.sub(/(Rails\.application\.routes\.draw do\n)/) { "#{$1}  #{ROUTE}\n" }
        if updated == content
          say "To do by hand: add #{ROUTE} inside the routes block.", :yellow
        else
          File.write(path, updated)
          say_status :update, ROUTES_FILE, :green
        end
      end

      def print_summary
        say "\nGallery ready: start the server and open /deckplate (development only).", :green
      end

      private

      def keep_existing(destination, source)
        if File.exist?(File.join(destination_root, destination))
          say_status :exist, "#{destination} (already there, left as is)", :blue
        else
          copy_file source, destination # copied as is: the view's ERB must not be evaluated now
        end
      end
    end
  end
end
