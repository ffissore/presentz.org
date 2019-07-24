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

assetManager = require "connect-assetmanager"
assetHandler = require "connect-assetmanager-handlers"
coffee = require "coffee-script"
dust = require "dustjs-linkedin"

coffee_compiler = (contents, path, index, isLast, callback) ->
  if /\.coffee/.test path
    console.log "Compiling #{path}"
    callback coffee.compile(contents)
  else
    callback contents

dust_compiler = (contents, path, index, isLast, callback) ->
  if /\.dust/.test path
    filename_parts = path.split("/")
    filename = filename_parts[filename_parts.length - 1]
    filename = filename.substring(0, filename.lastIndexOf("."))
    console.log "Compiling #{path} (#{filename})"
    callback dust.compile(contents, filename)
  else
    callback contents

new_js_conf = (suffix, files) ->
  conf =
    route: new RegExp("\/managedassets\/js\/[a-z0-9]*#{suffix}\.js")
    path: "./"
    dataType: "javascript"
    files: files
    stale: true
    debug: true
    preManipulate:
      "^": [
        coffee_compiler,
        dust_compiler
      ]
    postManipulate:
      "^": [
        assetHandler.uglifyJsOptimize
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
    "public/assets/js/jquery/jquery-1.8.0.js"
    "public/assets/js/jquery/jquery.easing.1.3.js"
    "public/assets/js/jquery/jquery.scrollTo-1.4.2-min.js"
    "public/assets/js/jquery/jquery-ui-1.8.23.custom.min.js"
    "public/assets/js/modernizr.js"
    "src_client/main.coffee"
  ])
  css: new_css_conf("main", [
    "public/assets/css/mediaelementplayer.css"
    "public/assets/css/reset.css"
    "public/assets/css/default.css"
    "public/assets/css/fluid_container.css"
    "public/assets/css/font_style.css"
    "public/assets/css/fe_style.css"
    "public/assets/css/default_responsive.css"
    "public/assets/css/fe_style_responsive.css"
  ])
  js_pres: new_js_conf("pres", [
    "public/assets/js/froogaloop.js"
    "public/assets/js/swfobject.js"
    "public/assets/js/mediaelement-and-player.js"
    "public/assets/js/presentz-1.3.1.js"
    "src_client/show_presentation.coffee"
  ])
  css_pres: new_css_conf("pres", [
    "public/assets/css/fe_style_pres.css"
  ])
  js_embed: new_js_conf("embed", ["src_client/embed.coffee"])
  js_manage: new_js_conf("manage", [
    "node_modules/accent-folding/accent-fold.js"
    "node_modules/xregexp/xregexp-all.js"
    "public/assets/js/jquery/jquery-1.8.0.js"
    "public/assets/js/jquery/jquery-ui-1.8.23.custom.min.js"
    "public/assets/js/manage/jquery.jsonp.js"
    "public/assets/js/manage/jquery.movingboxes.js"
    "public/assets/js/manage/bootstrap.js"
    "node_modules/underscore/underscore.js"
    "node_modules/underscore.string/lib/underscore.string.js"
    "public/assets/js/manage/backbone.js"
    "public/assets/js/manage/deep-model.js"
    "public/assets/js/manage/dust-core-1.0.0.js"
    "public/assets/js/manage/jsuri-1.1.1.js"
    "public/assets/js/froogaloop.js"
    "public/assets/js/swfobject.js"
    "public/assets/js/mediaelement-and-player.js"
    "public/assets/js/presentz-1.3.1.js"
    "views/m/_presentation_thumb.dust"
    "views/m/_presentation_menu_title_save_btn.dust"
    "views/m/_presentation.dust"
    "views/m/_slide.dust"
    "views/m/_reset_thumb.dust"
    "views/m/_img_slide_thumb.dust"
    "views/m/_swf_slide_thumb.dust"
    "views/m/_none_slide_thumb.dust"
    "views/m/_new.dust"
    "views/m/_slide_times_preview.dust"
    "views/m/_confirm_slide_delete.dust"
    "views/m/_no_talks_here.dust"
    "utils.coffee"
    "dustjs_helpers.coffee"
    "src_client_manage/backbone_extensions.coffee"
    "src_client_manage/namespaces.coffee"
    "src_client_manage/slide_backends/utils.coffee"
    "src_client_manage/slide_backends/slideshare.coffee"
    "src_client_manage/slide_backends/speakerdeck.coffee"
    "src_client_manage/slide_backends/dummy.coffee"
    "src_client_manage/slide_backends/none.coffee"
    "src_client_manage/video_backends/youtube.coffee"
    "src_client_manage/video_backends/vimeo.coffee"
    "src_client_manage/video_backends/dummy.coffee"
    "src_client_manage/models/presentation_thumb.coffee"
    "src_client_manage/models/presentation_thumb_list.coffee"
    "src_client_manage/models/presentation.coffee"
    "src_client_manage/views/utils.coffee"
    "src_client_manage/views/presentation_thumb_view.coffee"
    "src_client_manage/views/presentation_thumb_list_view.coffee"
    "src_client_manage/views/presentation_new_view.coffee"
    "src_client_manage/views/presentation_edit_view.coffee"
    "src_client_manage/views/app_view.coffee"
    "src_client_manage/views/navigation_view.coffee"
    "src_client_manage/router.coffee"
    "src_client_manage/main.coffee"
    "src_client_manage/validation.coffee"
  ])
  css_manage: new_css_conf("manage", [
    "public/assets/css/jquery-ui-1.8.23.custom.css"
    "public/assets/css/mediaelementplayer.css"
    "public/assets/css/bootstrap.css"
    "public/assets/css/bootstrap-responsive.css"
    "public/assets/css/fluid_container.css"
    "public/assets/css/movingboxes.css"
    "public/assets/css/manage.css"
  ])

exports.assetsMiddleware = assetsMiddleware