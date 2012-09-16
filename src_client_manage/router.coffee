class AppRouter extends Backbone.Router

  initialize: (@appView) ->

  routes:
    "": "go_mypres"
    "mypres": "mypres"
    "make": "make"
    "hp": "hp"
    ":presentation": "presentation"

  go_mypres: () ->
    @navigate("mypres", trigger: true)

  mypres: () ->
    @appView.mypres()

  make: () ->
    @appView.make()

  hp: () ->
    window.location = "/"

  presentation: (id) ->
    @appView.presentation(id)

@AppRouter = AppRouter