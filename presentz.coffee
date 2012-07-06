express = require "express"
messages = require "bootstrap-express-messages"
redirect_routes = require "./routes_redirect"
orient = require "orientdb"
cons = require "consolidate"
OrientDBStore = require("connect-orientdb")(express)
_ = require "underscore"
assetManager = require("connect-assetmanager")
assetHandler = require("connect-assetmanager-handlers")
handlers = require "./handlers"

Number:: pad = (pad) ->
  s = @.toString()
  while s.length < pad
    s = "0" + s
  s

app = express()

config = require "./config.#{app.settings.env}"

server = new orient.Server config.storage.server

db = new orient.GraphDb "presentz", server, config.storage.db

db.open (err) ->
  throw new Error(err) if err?
  console.log("DB connection open")

session_store_options = _.clone(config.storage)
session_store_options.database = "presentz"

everyauth = require("./auth").init(config, db)
api = require("./api").init(db)
routes = require("./routes").init(db)

assetsMiddleware = assetManager
  js_main:
    route: /\/assets\/js\/[a-z0-9]+main\.js/
    path: "./public/assets/js/"
    dataType: "javascript"
    files: [
      "jquery/jquery-1.7.1.min.js",
      "jquery/jquery.easing.1.3.js",
      "jquery/jquery.scrollTo-1.4.2-min.js",
      "modernizr.2.0.6.js",
      "main.js"
    ]
    stale: true
    preManipulate:
      "^": [
        handlers.coffeeRenderer
      ]
    postManipulate:
      "^": [
        assetHandler.uglifyJsOptimize
      ]
  js_pres:
    route: /\/assets\/js\/[a-z0-9]+pres\.js/
    path: "./public/assets/js/"
    dataType: "javascript"
    files: [
      "froogaloop.js",
      "swfobject.js",
      "presentz.js",
      "presentz.org.coffee"
    ]
    stale: true
    preManipulate:
      "^": [
        handlers.coffeeRenderer
      ]
    postManipulate:
      "^": [
        assetHandler.uglifyJsOptimize
      ]
  css:
    route: /\/assets\/css\/[a-z0-9]+\.css/
    path: "./public/assets/css/"
    dataType: "css"
    files: [
      "reset.css",
      "default.css",
      "font_style.css",
      "fe_style.css",
      "default_responsive.css",
      "fe_style_responsive.css"
    ]
    stale: true
    preManipulate:
      MSIE: [
        assetHandler.yuiCssOptimize,
        assetHandler.fixVendorPrefixes,
        assetHandler.fixGradients,
        assetHandler.stripDataUrlsPrefix
      ]
      "^": [
        assetHandler.yuiCssOptimize,
        assetHandler.fixVendorPrefixes,
        assetHandler.fixGradients,
        assetHandler.replaceImageRefToBase64(__dirname + "/public/assets/img/")
      ]

app.engine("dust", cons.dust)

app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "dust"
  app.use express.logger()
  app.use express.bodyParser()
  app.use express.cookieParser(config.presentz.session_secret)
  app.use assetsMiddleware
  app.use express.session
    store: new OrientDBStore(session_store_options)
  app.use messages(app)
  app.use express.methodOverride()
  app.use everyauth.middleware()
  app.use app.router
  app.use express.static "#{__dirname}/public"
  app.use redirect_routes.redirect_to "/"

app.configure "development", ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "production", ->
  app.use express.errorHandler()

app.locals.use (req, res, done) ->
  res.locals.assetsCacheHashes = assetsMiddleware.cacheHashes
  done()

app.get "/", routes.static "index"
app.get "/1/me/authored", api.mines_authored
app.get "/1/me/speaker_of", api.mines_held
app.get "/favicon.ico", express.static "#{__dirname}/public/assets/images"
app.get "/r/index.html", routes.static "index"
app.get "/r/tos.html", routes.static "tos"
app.get "/r/talks.html", routes.list_catalogs
app.get "/p.html", redirect_routes.redirect_to_presentation_from_p_html
#app.get "/m/*.:whatever?", routes.ensure_is_logged
app.get "/m/manage", routes.static "m/index"
app.get "/:catalog_name/p.html", redirect_routes.redirect_to_presentation_from_p_html
app.get "/:catalog_name/catalog.html", routes.show_catalog
app.get "/:catalog_name/catalog", routes.show_catalog
app.get "/:catalog_name/index.html", routes.show_catalog
app.get "/:catalog_name/:presentation.html", redirect_routes.redirect_to_presentation_from_html
app.get "/:catalog_name/:presentation.json", routes.raw_presentation
app.get "/:catalog_name/:presentation", routes.show_presentation
app.get "/:catalog_name", routes.show_catalog

app.listen 3000
console.log "Express server listening on port 3000 in %s mode", app.settings.env

require "./subdomain"