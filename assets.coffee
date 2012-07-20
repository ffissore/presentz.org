assetManager = require("connect-assetmanager")
assetHandler = require("connect-assetmanager-handlers")
coffee = require "coffee-script"

coffee_renderer = (file, path, index, isLast, callback) ->
  if /\.coffee/.test path
    console.log "Compiling #{path}"
    callback coffee.compile(file)
  else
    callback file

new_js_conf = (suffix, files) ->
  conf =
    route: new RegExp("\/managedassets\/js\/[a-z0-9]+#{suffix}\.js")
    path: "./public/assets/js/"
    dataType: "javascript"
    files: files
    stale: true
    preManipulate:
      "^": [
        coffee_renderer
      ]
    postManipulate:
      "^": [
        assetHandler.uglifyJsOptimize
      ]
  return conf

new_css_conf = (suffix, files) ->
  conf =
    route: new RegExp("/managedassets\/css\/[a-z0-9]+#{suffix}\.css")
    path: "./public/assets/css/"
    dataType: "css"
    files: files
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
        assetHandler.replaceImageRefToBase64("#{__dirname}/public/assets/img/")
      ]
  return conf


exports.assetsMiddleware = assetManager
  js_main: new_js_conf("main", [
    "jquery/jquery-1.7.2.min.js",
    "jquery/jquery.easing.1.3.js",
    "jquery/jquery.scrollTo-1.4.2-min.js",
    "jquery/jquery-ui-1.8.21.custom.min.js",
    "modernizr.js",
    "main.coffee"
  ])
  js_pres: new_js_conf("pres", [
    "froogaloop.js",
    "swfobject.js",
    "mediaelement-and-player.js",
    "presentz.js",
    "show_presentation.coffee"
  ])
  css: new_css_conf("main", [
    "mediaelementplayer.css",
    "reset.css",
    "default.css",
    "font_style.css",
    "fe_style.css",
    "default_responsive.css",
    "fe_style_responsive.css"
  ])
  css_pres: new_css_conf("pres", [
    "fe_style_pres.css"
  ])