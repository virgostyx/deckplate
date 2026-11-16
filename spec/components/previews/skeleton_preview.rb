# @label Feedback / Skeleton
class SkeletonPreview < ViewComponent::Preview
  def default
    render_with_template(template: "skeleton_preview/default")
  end

  def shapes
    render_with_template(template: "skeleton_preview/shapes")
  end
end
