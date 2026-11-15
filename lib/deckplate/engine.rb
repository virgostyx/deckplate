module Deckplate
  class Engine < ::Rails::Engine
    isolate_namespace Deckplate

    # config.form_builder = true makes Deckplate::FormBuilder the default builder of every form_with / form_for
    def self.apply_default_form_builder
      ActionView::Base.default_form_builder = Deckplate::FormBuilder if Deckplate.configuration.form_builder
    end

    config.after_initialize { Deckplate::Engine.apply_default_form_builder }

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
