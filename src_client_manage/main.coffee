jQuery () ->
  class Presentation extends Backbone.DeepModel

  class PresentationList extends Backbone.Collection

    url: "/m/api/my_presentations"

    model: Presentation

  class PresentationView extends Backbone.View

    tagName: "ul"
    
    className: "thumbnails"

    render: () ->
      @model.each (model) =>
        @$el.append """
        <li class="span3">
          <div class="thumbnail">    
            <img src="#{model.get "chapters.0.video.thumb"}" alt="">
            <h5>#{utils.cut_string_at(model.get("title"), 30)}</h5>
            <p><a href="#" class="btn btn-primary">Add</a> <a href="#" class="btn btn-warning">Swap</a> <a href="#" class="btn btn-danger">Remove</a></p>
          </div>
        </li> 
        """
      @

  class AppView extends Backbone.View

    el: $ "body > .container"

    initialize: () ->
      @presentationList = new PresentationList()

      @presentationList.on "reset", @reset, @

      @render()

      @presentationList.fetch()

    reset: (model) ->
      console.log model
      @$el.empty()
      view = new PresentationView model: model
      @$el.html(view.render().el)
      
  app = new AppView()