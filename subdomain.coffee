express = require "express"
redirect_routes = require "./routes/redirect"

subdomain = express.createServer()

subdomain.configure ->
  subdomain.use express.logger()
  subdomain.use express.methodOverride()
  subdomain.use redirect_routes.redirect_to_catalog_if_subdomain()
  subdomain.use redirect_routes.redirect_to "http://presentz.org/"
  subdomain.use express.errorHandler()

subdomain.listen 3001
console.log "Express server listening on port %d in %s mode", subdomain.address().port, subdomain.settings.env
