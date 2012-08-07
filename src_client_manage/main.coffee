jQuery () ->
  
  class Item extends Backbone.Model
    
    defaults:
      thumb: "http://placehold.it/260x180"
      title: "Presentation title"
      
  class List extends Backbone.Collection
    
    model: Item
    
  class ItemView extends Backbone.View
    
    tagName: "li"
    
    initialize: () ->
      _.bindAll @
      
      @model.bind "change", @render
      @model.bind "remove", @unrender
      
    render: () ->
      @$el.html """
        <div class="thumbnail">    
          <img src="http://placehold.it/260x180" alt="">
          <h5>#{@model.get "title"}</h5>
          <p>Thumbnail caption right here...</p>        
          <p><a href="#" class="btn btn-primary">Add</a> <a href="#" class="btn btn-warning">Swap</a> <a href="#" class="btn btn-danger">Remove</a></p>
        </div>
      """
      @
      
    unrender: () ->
      @$el.remove()
      
    swap: () ->
      @model.set
        title: "Changed title"
      @model.save()
      false

    remove: () ->
      @model.destroy()
      false

    events:
      "click a.btn.btn-warning": "swap"
      "click a.btn.btn-danger": "remove"
      
  class ListView extends Backbone.View
    
    el: $ "body > .container"
    
    initialize: () ->
      _.bindAll @
      
      @collection = new List
      @collection.bind "add", @appendItem
      
      @counter = 0
      @render()
      
    render: () ->
      @$el.append """
        <ul class="thumbnails">
          <li class="span3">
            <div class="thumbnail">    
              <img src="http://placehold.it/260x180" alt="">
              <h5>Thumbnail label</h5>
              <p>Thumbnail caption right here...</p>        
              <p><a href="#" class="btn btn-primary">Add</a> <a href="#" class="btn">Remove</a></p>
            </div>
          </li>
        </ul>
      """
      
    addItem: () ->
      @counter++
      
      item = new Item
      item.set
        title: "Title of #{@counter}"
      
      @collection.add item
      false

    appendItem: (item) ->
      itemView = new ItemView model: item
      
      $(".thumbnails", @el).append itemView.render().el
      
    events: "click a.btn.btn-primary": "addItem"

  Backbone.sync = (method, model, options) ->
    console.log arguments
    
    options.success()
    
  listView = new ListView()

###
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
###