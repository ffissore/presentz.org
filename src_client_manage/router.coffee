"use strict"

class AppRouter extends Backbone.Router

  initialize: (@app_view) ->
    _.bindAll(@)
    
    @app_view.bind "edit_presentation", (id) =>
      @navigate(id, trigger: true)

    @app_view.bind "new_presentation", (id) =>
      @navigate(id)
    @app_view.bind "mypres", () =>
      @go_mypres()

  routes:
    "": "go_mypres"
    "mypres": "mypres"
    "make": "make"
    "hp": "hp"
    ":presentation": "presentation"

  go_mypres: () ->
    @navigate("mypres", trigger: true)

  mypres: () ->
    @app_view.mypres()

  make: () ->
    @app_view.make()

  hp: () ->
    window.location = "/"

  presentation: (id) ->
    @app_view.presentation(id)

@AppRouter = AppRouter