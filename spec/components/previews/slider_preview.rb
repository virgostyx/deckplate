# @label Controls / Slider
class SliderPreview < ViewComponent::Preview
  # Native range input; drag it or use the arrow keys, the readout follows
  def default
    render_with_template(template: "slider_preview/default")
  end

  # Unit, step, no readout, disabled, colours
  def variants
    render_with_template(template: "slider_preview/variants")
  end
end
