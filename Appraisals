appraise "rails-8-0" do
  gem "rails", "~> 8.0.0"
  # Rails 8.0 still passes `quirks_mode` to JSON.generate, which json 3.x removed (fixed in Rails 8.1).
  gem "json", "< 3"
end

appraise "rails-8-1" do
  gem "rails", "~> 8.1.0"
end
