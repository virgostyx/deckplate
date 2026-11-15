# A page served with a strict Content-Security-Policy (no inline style, no inline script without a nonce): the proof that
# csp_safe_values really works in a browser.
class CspController < ApplicationController
  content_security_policy do |policy|
    policy.default_src :none
    policy.script_src :self
    policy.style_src :self
    policy.font_src :self
    policy.connect_src :self
    policy.img_src :self
  end

  def show; end
end
