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
          <p><a href="#" class="publish btn#{published_css_class}">#{published_label}</a> <a href="#" class="edit btn">Edit</a></p>
        </div>
      """
      @

    toogle_published: () ->
      @model.set "published", !@model.get "published"
      @model.save()
      false

    edit: () ->
      @options.navigationView.reset()
      @options.navigationView.append "<li class=\"active\"><a href=\"#edit\">#{utils.cut_string_at(@model.get("title"), 30)}</a></li>"
      false

    events:
      "click a.publish": "toogle_published"
      "click a.edit": "edit"

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
        view = new PresentationView 
          model: model
          navigationView: @options.navigationView
        @$el.append view.render().el
      @

  class NavigationView extends Backbone.View

    el: $(".navbar > .navbar-inner > .container > .nav-collapse > .nav")

    reset: (home) ->
      $("li:gt(1)", @$el).remove()
      $("li", @$el).removeClass "active"
      $("li:first", @$el).addClass "active" if home?

    append: (html) ->
      @$el.append(html)

    events:
      "click a[href=#home]": "reset"

  class AppView extends Backbone.View

    el: $ "body > .container"

    initialize: () ->
      @navigationView = new NavigationView()

      @presentationList = new PresentationList()

      @presentationList.on "reset", @reset, @

      @render()

      @presentationList.fetch()

    events:
      "click .navbar .container .nav li a[href=#home]": "reset"

    reset: (model) ->
      @navigationView.reset(true)

      @$el.empty()
      view = new PresentationListView
        model: model
        navigationView: @navigationView
      @$el.html view.render().el

  app = new AppView()