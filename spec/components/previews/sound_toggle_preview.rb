# @label Controls / SoundToggle
class SoundTogglePreview < ViewComponent::Preview
  # The mute switch. It renders only when config.sounds = true; the state is stored in localStorage.
  def default
    render_with_template(template: "sound_toggle_preview/default")
  end
end
