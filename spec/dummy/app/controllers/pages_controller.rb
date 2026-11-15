# Catch-all page for the dummy app: routing targets for component specs and Turbo system specs.
class PagesController < ApplicationController
  def show
    @path = request.path
  end
end
