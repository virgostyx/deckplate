# @label Token gallery
class TokenGalleryPreview < ViewComponent::Preview
  # Every palette stop, semantic role, surface token, the type scale and the spacing scale.
  # Use the toolbar's "theme" dropdown to switch themes.
  def default
    render_with_template(template: "token_gallery_preview/default", locals: {
      stops: YAML.load_file(Deckplate::Engine.root.join("config/deckplate/palette.yml")).fetch("stops"),
      roles: Deckplate::Concerns::Colorable::ROLES,
      surfaces: %w[canvas surface surface-raised ink ink-muted line focus disabled]
    })
  end
end
