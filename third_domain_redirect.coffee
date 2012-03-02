express = require "express"
routes = require "./routes"

app = express.createServer()

app.configure ->
  app.use express.logger()
  app.use express.methodOverride() 
  app.use routes.redirect_to_catalog_if_subdomain()
  app.use routes.redirect_to "http://presentz.org/"

app.configure "development", ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure "production", ->
  app.use express.errorHandler()

app.listen 3001 
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env 
