express = require "express"
orient = require "orientdb"
cons = require "consolidate"
OrientDBStore = require("connect-orientdb")(express)
_ = require "underscore"

redirect_routes = require "./routes_redirect"
storage = require "./storage"
auth = require "./auth"
assets = require "./assets"
api = require "./api"
routes = require "./routes"

Number:: pad = (pad, pad_char = "0") ->
  s = @.toString()
  while s.length < pad
    s = "#{pad_char}#{s}"
  s

ONE_WEEK = 604800000
  
app = express()

config = require "./config.#{app.settings.env}"

server = new orient.Server config.storage.server

db = new orient.GraphDb "presentz", server, config.storage.db

db.open (err) ->
  throw new Error(err) if err?
  console.log("DB connection open")

session_store_options = _.clone(config.storage)
session_store_options.database = "presentz"

storage.init db
everyauth = auth.init(config, db)
api.init(storage, config.slideshare)
routes.init(storage, auth)

app.engine("dust", cons.dust)

app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "dust"
  app.enable "view cache"
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.cookieParser(config.presentz.session_secret)
  app.use assets.assetsMiddleware
  app.use express.session
    store: new OrientDBStore(session_store_options)
    cookie:
      maxAge: ONE_WEEK
  app.use express.methodOverride()
  app.use everyauth.middleware()
  app.use auth.put_user_in_locals
  app.use app.router
  app.use express.static "#{__dirname}/public"
  app.use redirect_routes.redirect_to "/"

app.configure "development", ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "test", ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "production", ->
  app.use express.errorHandler()

app.locals
  assetsCacheHashes: assets.assetsMiddleware.cacheHashes

app.get "/", routes.static_view "index"
app.get "/favicon.ico", express.static "#{__dirname}/public/assets/img"
app.get "/robots.txt", express.static "#{__dirname}/public/assets"
app.get "/r/back_to_referer", redirect_routes.back_to_referer config
app.get "/r/index.html", routes.static_view "index"
app.get "/r/tos.html", routes.static_view "tos"
app.get "/r/talks.html", routes.list_catalogs
app.all "/m/*", routes.ensure_is_logged
app.get "/m/", routes.static_view "m/index"
app.get "/m/api/presentations/:presentation", api.presentation_load
app.put "/m/api/presentations/:presentation", api.presentation_save
#app.post "/m/api/presentations", api.presentation_save
app.get "/m/api/presentations", api.presentations
app.get "/m/api/slideshare/url_to_doc_id", api.slideshare_url_to_doc_id
app.get "/m/api/slideshare/:doc_id", api.slideshare_slides_of
app.delete "/m/api/delete_slide/:node_id", api.delete_slide

app.get "/u/fb/:user_name", routes.show_catalog_of_user auth.socials_prefixes.facebook
app.get "/u/tw/:user_name", routes.show_catalog_of_user auth.socials_prefixes.twitter
app.get "/u/go/:user_name", routes.show_catalog_of_user auth.socials_prefixes.google
app.get "/u/in/:user_name", routes.show_catalog_of_user auth.socials_prefixes.linkedin
app.get "/u/gh/:user_name", routes.show_catalog_of_user auth.socials_prefixes.github
app.get "/u/fs/:user_name", routes.show_catalog_of_user auth.socials_prefixes.foursquare
app.get "/u/:social_prefix/:user_name/:presentation.json", routes.raw_presentation_from_user
app.get "/u/:social_prefix/:user_name/:presentation", routes.show_presentation_from_user
app.post "/u/:social_prefix/:user_name/:presentation/comment", routes.comment_presentation

app.get "/:catalog_name/catalog.html", routes.show_catalog
app.get "/:catalog_name/catalog", routes.show_catalog
app.get "/:catalog_name/index.html", routes.show_catalog
app.get "/:catalog_name/:presentation.json", routes.raw_presentation_from_catalog
app.get "/:catalog_name/:presentation", routes.show_presentation_from_catalog
app.get "/:catalog_name", routes.show_catalog
app.post "/:catalog_name/:presentation/comment", routes.comment_presentation

app.listen config.port
console.log "Express server listening on port #{config.port} in #{app.settings.env} mode"

require "./subdomain"