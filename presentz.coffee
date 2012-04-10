express = require "express"
routes = require "./routes"
redirect_routes = require "./routes/redirect"
orient = require "orientdb"

app = express.createServer()

config = require "./config.#{app.settings.env}"

server = new orient.Server
  host: config.storage.server.host
  port: config.storage.server.port

db = new orient.Db "presentz", server,
  user_name: config.storage.db.user_name
  user_password: config.storage.db.user_password

db.open ->
  console.log("DB connection open")

everyauth = require("./auth").init(config, db)

app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session { secret: config.presentz.session_secret }
  app.use express.methodOverride()
  app.use everyauth.middleware()
  app.use app.router
  app.use express.static "#{__dirname}/public"
  app.use redirect_routes.redirect_to "/"

app.configure "development", ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.static "index"
app.get "/r/index.html", routes.static "index"
app.get "/r/about.html", routes.static "about"
app.get "/r/tos.html", routes.static "tos"
app.get "/p.html", redirect_routes.redirect_to_presentation_from_p_html
app.get "/:catalog_name/p.html", redirect_routes.redirect_to_presentation_from_p_html
app.get "/:catalog_name/catalog.html", routes.show_catalog
app.get "/:catalog_name/catalog", routes.show_catalog
app.get "/:catalog_name/index.html", routes.show_catalog
app.get "/:catalog_name/:presentation.html", redirect_routes.redirect_to_presentation_from_html
app.get "/:catalog_name/:presentation.json", routes.raw_presentation
app.get "/:catalog_name/:presentation", routes.show_presentation
app.get "/:catalog_name", routes.show_catalog

everyauth.helpExpress(app)

app.listen 3000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env

require "./subdomain"