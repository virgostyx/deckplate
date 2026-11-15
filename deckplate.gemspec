require_relative "lib/deckplate/version"

Gem::Specification.new do |spec|
  spec.name        = "deckplate"
  spec.version     = Deckplate::VERSION
  spec.authors     = [ "Deckplate contributors" ]
  spec.summary     = "Themeable, accessible Rails UI components with a retro-futuristic console look."
  spec.description = "ViewComponents, plain CSS (custom properties, cascade layers) and Stimulus controllers for building starship-console style interfaces."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["{app,config,lib}/**/*", "LICENSE", "README.md", "CHANGELOG.md", "CREDITS.md"]

  spec.add_dependency "rails", ">= 8.0", "< 8.2"
  spec.add_dependency "view_component", ">= 4.0", "< 5.0"
end
