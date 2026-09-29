# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Compiled cssbundling output and vendored Bootstrap live here — not node_modules,
# which is absent from Capistrano releases unless yarn install has run.
Rails.application.config.assets.paths.unshift(Rails.root.join("app/assets/builds"))
Rails.application.config.assets.paths << Rails.root.join("vendor/javascript")
