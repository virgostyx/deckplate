# @label Shapes / Block
class BlockPreview < ViewComponent::Preview
  # A labelled block
  def default
    render_with_template(template: "block_preview/default")
  end

  # Shapes x alignments
  def variants
    render_with_template(template: "block_preview/variants")
  end

  # A realistic composition: numbered navigation blocks stacked in a column, plus overflow
  def stack
    render_with_template(template: "block_preview/stack")
  end
end
