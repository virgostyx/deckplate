# axe-core-rspec assumes Selenium; with Cuprite we inject the axe-core bundled in the axe-core-api gem and run it ourselves.
module AxeCuprite
  TAGS = %w[wcag2a wcag2aa wcag21a wcag21aa wcag22aa].freeze

  def self.source
    @source ||= File.read(File.join(Gem.loaded_specs.fetch("axe-core-api").full_gem_path, "node_modules/axe-core/axe.min.js"))
  end

  # Returns the list of violations (empty when clean) for the current page.
  def axe_violations(tags: TAGS)
    page.execute_script(AxeCuprite.source) unless page.evaluate_script("typeof window.axe") == "object"
    result = page.evaluate_async_script(<<~JS, tags)
      var tags = arguments[0], done = arguments[arguments.length - 1];
      axe.run(document, { runOnly: { type: "tag", values: tags } })
        .then(function (r) { done(JSON.stringify(r.violations)); })
        .catch(function (e) { done(JSON.stringify([{ id: "axe-error", help: String(e), nodes: [] }])); });
    JS
    JSON.parse(result)
  end

  def axe_report(violations)
    violations.map do |v|
      targets = v["nodes"].first(4).map { |n| "      #{n['target'].join(' ')}  #{n.dig('any', 0, 'message')}" }.join("\n")
      "  [#{v['impact']}] #{v['id']}: #{v['help']} (#{v['nodes'].size} node(s))\n#{targets}"
    end.join("\n")
  end
end

RSpec.configure { |c| c.include AxeCuprite, type: :system }
