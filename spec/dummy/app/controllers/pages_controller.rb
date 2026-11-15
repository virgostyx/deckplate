# Catch-all page for the dummy app: routing targets for component specs and Turbo system specs.
class PagesController < ApplicationController
  def show
    @path = request.path
  end

  # Fake form endpoint for Turbo specs: 303 redirect on success, 422 with a re-rendered form when params[:fail] is set.
  def create
    if params[:fail].present?
      render plain: "Invalid", status: :unprocessable_entity
    else
      redirect_to "/ships", status: :see_other
    end
  end
end
