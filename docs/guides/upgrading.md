# Upgrading

Deckplate follows semantic versioning; before 1.0 a minor version (0.x) may change the API. Read `CHANGELOG.md` first.

1. Update the gem (`bundle update deckplate`).
2. Run `bin/rails g deckplate:install` again: it adds what is new and changes nothing else.
3. Tailwind hosts: delete `app/assets/tailwind/deckplate-bridge.css` before step 2 to get the current token list.
4. Compare `config/initializers/deckplate.rb` with the options listed in the README (new options are documented in the CHANGELOG).
5. Custom themes (`rails g deckplate:theme`) must define every token of the built-in themes; add the new ones the CHANGELOG lists.
6. Run your system tests; if you take screenshots, expect small visual changes noted in the CHANGELOG.
