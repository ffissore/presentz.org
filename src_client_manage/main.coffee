jQuery () ->
  class Presentation extends Backbone.DeepModel

  class PresentationView extends Backbone.View

    tagName: "li"

    className: "span3"

    initialize: () ->
      _.bindAll @

      @model.bind "change", @render
    
    render: () ->
      if @model.get("published")
        published_css_class = ""
        published_label = "Published"
      else
        published_css_class = " btn-danger"
        published_label = "Hidden"

      @$el.html """
        <div class="thumbnail">    
          <img src="#{@model.get "chapters.0.video.thumb"}" alt="">
          <h5>#{utils.cut_string_at(@model.get("title"), 30)}</h5>
          <p><a href="#" class="publish btn#{published_css_class}">#{published_label}</a></p>
        </div>
      """
      @

    toogle_published: () ->
      @model.set "published", !@model.get "published"
      @model.save()

    events:
      "click a.publish": "toogle_published"

  class PresentationList extends Backbone.Collection

    url: "/m/api/presentations"

    model: Presentation

    comparator: (presentation) ->
      presentation.get("title")

  class PresentationListView extends Backbone.View

    tagName: "ul"

    className: "thumbnails"

    render: () ->
      @model.each (model) =>
        view = new PresentationView model: model
        @$el.append view.render().el
      @

  class AppView extends Backbone.View

    el: $ "body > .container"

    initialize: () ->
      @presentationList = new PresentationList()

      @presentationList.on "reset", @reset, @

      @render()

      @presentationList.fetch()

    reset: (model) ->
      @$el.empty()
      view = new PresentationListView model: model
      @$el.html view.render().el

  app = new AppView()