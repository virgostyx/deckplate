# Turbo Stream toasts demo: the response appends a ToastComponent to the #dp-toasts container (dp_toast_container).
class ToastsController < ApplicationController
  def show; end

  def create
    kind = %w[info success warning danger].include?(params[:kind]) ? params[:kind].to_sym : :info
    duration = params[:duration].presence&.to_i
    message = params[:message].presence || "A #{kind} toast"
    render turbo_stream: turbo_stream.append("dp-toasts", Deckplate::Feedback::ToastComponent.new(kind: kind, duration: duration).with_content(message))
  end
end
