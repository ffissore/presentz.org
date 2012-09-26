"use strict"

express = require "express"
redirect_routes = require "./routes_redirect"

subdomain = express()

config = require "./config.#{subdomain.settings.env}"

subdomain.configure ->
  subdomain.use express.logger()
  subdomain.use express.methodOverride()
  subdomain.use redirect_routes.redirect_to_catalog_if_subdomain()
  subdomain.use redirect_routes.redirect_to "http://presentz.org/"
  subdomain.use express.errorHandler()

subdomain.listen config.subdomain_port
console.log "Express server listening on port #{config.subdomain_port} in #{subdomain.settings.env} mode"
