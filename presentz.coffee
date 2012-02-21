express = require "express"
routes = require "./routes"
rewrite = require "./rewrite"

app = express.createServer()

app.configure ->
  app.set "views", "#{__dirname}/views" 
  app.set "view engine", "jade" 
  app.use rewrite.rewriter "assets"
  app.use express.logger()
  app.use express.bodyParser() 
  app.use express.methodOverride() 
  app.use app.router
  app.use express.static "#{__dirname}/public"

app.configure "development", ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true }) 

app.configure "production", ->
  app.use express.errorHandler() 

app.get "/", routes.index 
app.get "/:catalog_name/:presentation.js", routes.raw_presentation
app.get "/:catalog_name/:presentation", routes.show_presentation
app.get "/:catalog_name", routes.show_catalog

app.listen 3000 
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env 
