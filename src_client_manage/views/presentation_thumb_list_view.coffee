class PresentationThumbListView extends Backbone.View

  tagName: "ul"

  className: "thumbnails"

  initialize: () ->
    _.bindAll(@)

  render: () ->
    views.scroll_top()
    
    @model.each (model) =>
      view = new views.PresentationThumbView(model: model)
      view.render().bind("edit", @edit)
      @$el.append(view.el)
    @
  
  edit: (id) ->
    @trigger("edit", id)
    false

@views.PresentationThumbListView = PresentationThumbListView