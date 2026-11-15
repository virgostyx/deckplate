# Parses Deckplate's CSS custom properties and computes WCAG contrast. No manual claims: specs read the real CSS.
module CssVars
  ROOT = Deckplate::Engine.root

  module_function

  def palette
    @palette ||= YAML.load_file(ROOT.join("config/deckplate/palette.yml")).fetch("stops")
  end

  # { "--dp-primary" => "var(--dp-neon-carrot)" } for one theme file
  def theme_vars(name)
    css = File.read(ROOT.join("app/assets/stylesheets/deckplate/themes/#{name}.css"))
    block = css[/\[data-dp-theme="#{name}"\]\s*\{(.*?)\}/m, 1] or raise "no [data-dp-theme=#{name}] block"
    block.scan(/(--dp-[a-z0-9-]+)\s*:\s*([^;]+);/).to_h { |k, v| [ k, v.strip ] }
  end

  def stop_vars
    palette.each_with_object({}) do |(n, s), h|
      h["--dp-#{n}"] = s["hex"]
      h["--dp-#{n}-ink"] = s["ink"]
    end
  end

  # Resolves var(--x) chains to "#rrggbb"
  def resolve(value, vars)
    value = value.strip
    return value.upcase if value.match?(/\A#\h{6}\z/)
    if (m = value.match(/\Avar\((--[a-z0-9-]+)\)\z/))
      raise KeyError, "undefined #{m[1]}" unless vars.key?(m[1])
      return resolve(vars.fetch(m[1]), vars)
    end
    raise ArgumentError, "cannot resolve #{value.inspect}"
  end

  def luminance(hex)
    hex.delete("#").scan(/../).map { |c| v = c.to_i(16) / 255.0; v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4 }
       .then { |r, g, b| 0.2126 * r + 0.7152 * g + 0.0722 * b }
  end

  def contrast(a, b)
    hi, lo = [ luminance(a), luminance(b) ].max, [ luminance(a), luminance(b) ].min
    (hi + 0.05) / (lo + 0.05)
  end
end
