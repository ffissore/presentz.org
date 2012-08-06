Router = Backbone.Router.extend 
  routes:
    "": "home"
    
  initialize: ->
    $(".header").html("Hello")
    return
  
  home: ->
    #nothing
    
new Router()
Backbone.history.start()