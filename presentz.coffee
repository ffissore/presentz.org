express = require "express"
routes = require "./routes"

app = express.createServer()

app.configure ->
  app.set "views", "#{__dirname}/views" 
  app.set "view engine", "jade" 
  app.use express.logger()
  app.use express.bodyParser() 
  app.use express.methodOverride() 
  app.use routes.catalog_name_by_third_domain()
  app.use app.router
  app.use express.static "#{__dirname}/public"
  app.use routes.redirect_to_home

app.configure "development", ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.static "index"
app.get "/r/index.html", routes.static "index" 
app.get "/r/about.html", routes.static "about" 
app.get "/r/tos.html", routes.static "tos" 
app.get "/:catalog_name/p.html", routes.redirect_to_presentation_from_p_html
app.get "/:catalog_name/catalog.html", routes.show_catalog
app.get "/:catalog_name/catalog", routes.show_catalog
app.get "/:catalog_name/index.html", routes.show_catalog
app.get "/:catalog_name/:presentation.html", routes.redirect_to_presentation_from_html
app.get "/:catalog_name/:presentation.json", routes.raw_presentation
app.get "/:catalog_name/:presentation", routes.show_presentation
app.get "/:catalog_name", routes.show_catalog

app.listen 3000 
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env 
