assetManager = require "connect-assetmanager"
assetHandler = require "connect-assetmanager-handlers"
coffee = require "coffee-script"

coffee_renderer = (file, path, index, isLast, callback) ->
  if /\.coffee/.test path
    console.log "Compiling #{path}"
    callback coffee.compile(file)
  else
    callback file

new_js_conf = (suffix, files) ->
  conf =
    route: new RegExp("\/managedassets\/js\/[a-z0-9]*#{suffix}\.js")
    path: "./"
    dataType: "javascript"
    files: files
    stale: true
    preManipulate:
      "^": [
        coffee_renderer
      ]
    postManipulate:
      "^": [
        #assetHandler.uglifyJsOptimize
      ]
  return conf

new_css_conf = (suffix, files) ->
  conf =
    route: new RegExp("/managedassets\/css\/[a-z0-9]+#{suffix}\.css")
    path: "./"
    dataType: "css"
    files: files
    stale: true
    preManipulate:
      MSIE: [
        assetHandler.fixVendorPrefixes,
        assetHandler.fixGradients,
        assetHandler.stripDataUrlsPrefix
      ]
      "^": [
        assetHandler.fixVendorPrefixes,
        assetHandler.fixGradients,
        assetHandler.replaceImageRefToBase64("#{__dirname}/public/assets/img/")
      ]
  return conf


assetsMiddleware = assetManager
  js_main: new_js_conf("main", [
    "public/assets/js/jquery/jquery-1.7.2.min.js",
    "public/assets/js/jquery/jquery.easing.1.3.js",
    "public/assets/js/jquery/jquery.scrollTo-1.4.2-min.js",
    "public/assets/js/jquery/jquery-ui-1.8.21.custom.min.js",
    "public/assets/js/modernizr.js",
    "src_client/main.coffee"
  ])
  css: new_css_conf("main", [
    "public/assets/css/mediaelementplayer.css",
    "public/assets/css/reset.css",
    "public/assets/css/default.css",
    "public/assets/css/font_style.css",
    "public/assets/css/fe_style.css",
    "public/assets/css/default_responsive.css",
    "public/assets/css/fe_style_responsive.css"
  ])
  js_pres: new_js_conf("pres", [
    "public/assets/js/froogaloop.js",
    "public/assets/js/swfobject.js",
    "public/assets/js/mediaelement-and-player.js",
    "public/assets/js/presentz.js",
    "src_client/show_presentation.coffee"
  ])
  css_pres: new_css_conf("pres", [
    "public/assets/css/fe_style_pres.css"
  ])
  js_embed: new_js_conf("embed", ["src_client/embed.coffee"])
  js_manage: new_js_conf("manage", [
    "public/assets/js/jquery/jquery-1.7.2.min.js",
    "public/assets/js/manage/bootstrap.js",
    "public/assets/js/manage/underscore.js",
    "public/assets/js/manage/backbone.js",
    "utils.coffee",
    "src_client_manage/main.coffee"
  ])
  css_manage: new_css_conf("manage", [
    "public/assets/css/bootstrap.css",
    "public/assets/css/bootstrap-responsive.css"
    "public/assets/css/manage.css"
  ])

exports.assetsMiddleware = assetsMiddleware