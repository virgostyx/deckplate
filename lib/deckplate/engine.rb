module Deckplate
  class Engine < ::Rails::Engine
    isolate_namespace Deckplate

    initializer "deckplate.helpers" do
      ActiveSupport.on_load(:action_view) { include Deckplate::Helpers }
    end

    initializer "deckplate.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
      end
    end

    initializer "deckplate.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end
  end
end
