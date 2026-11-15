# Prints every Lookbook/ViewComponent preview example as JSON: ["token_gallery/default", ...]
# Usage: cd spec/dummy && bin/rails runner ../../tools/visual/previews.rb
require "json"
puts ViewComponent::Preview.all.flat_map { |preview| preview.examples.map { |example| "#{preview.preview_name}/#{example}" } }.sort.to_json
