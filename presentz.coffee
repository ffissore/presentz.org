###
Presentz.org - A website to publish presentations with video and slides synchronized.

Copyright (C) 2012 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

"use strict"

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

Number::pad = (pad, pad_char = "0") ->
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
  app.enable "trust proxy"
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
  app.use express.static "#{__dirname}/public" if app.settings.env is "development"
  app.use app.router
  app.use redirect_routes.redirect_to "/"

app.configure "development", ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "test", ->
  app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "production", ->
  app.use express.errorHandler()

app.locals
  assetsCacheHashes: assets.assetsMiddleware.cacheHashes

generic_description = "The purpose of Presentz is to allow everyone to faithfully reproduce presentations and conference talks, without imposing any technology constraint. Presentz is a mashup, as it merges things like Vimeo, Youtube, Slideshare and Speakerdeck. But you can use images and video files as well, unleashing the HTML5 video tag power."

app.get "/", routes.static_view "index", "Presentz", "Presentz", generic_description
app.get "/favicon.ico", express.static "#{__dirname}/public/assets/img"
app.get "/robots.txt", express.static "#{__dirname}/public/assets"
app.get "/r/back_to_referer", redirect_routes.back_to_referer config
app.get "/r/tos.html", routes.static_view "tos", "Terms of Service", "Terms of Service - Presentz", generic_description
app.get "/r/talks.html", routes.list_catalogs
app.all "/m/*", routes.ensure_is_logged
app.get "/m/", routes.static_view "m/index", "Presentz Maker", "Presentz Maker", "Presentz Maker"
app.get "/m/api/presentations/:presentation", api.presentation_load
app.put "/m/api/presentations/:presentation", api.presentation_save
#app.post "/m/api/presentations", api.presentation_save
app.get "/m/api/presentations", api.presentations
app.get "/m/api/slideshare/url_to_doc_id", api.slideshare_url_to_doc_id
app.get "/m/api/slideshare/:doc_id", api.slideshare_slides_of
app.get "/m/api/speakerdeck/url_to_data_id", api.speakerdeck_url_to_data_id
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