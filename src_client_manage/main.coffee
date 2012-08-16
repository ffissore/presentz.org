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

      ctx =
        thumb: @model.get "chapters.0.video.thumb"
        title: utils.cut_string_at(@model.get("title"), 30)
        published_css_class: published_css_class
        published_label: published_label
      dust.render "_presentation_thumb", ctx, (err, out) =>
        @$el.html out
      @

    toogle_published: () ->
      @model.set "published", !@model.get "published"
      @model.save()
      false

    edit: () ->
      dispatcher.trigger "new_menu_entry", title: utils.cut_string_at(@model.get("title"), 30)
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
        view = new PresentationView model: model
        @$el.append view.render().el
      @

  class NavigationView extends Backbone.View

    el: $(".navbar > .navbar-inner > .container > .nav-collapse > .nav")

    reset: (home) ->
      $("li:gt(1)", @$el).remove()
      $("li", @$el).removeClass "active"
      $("li:first", @$el).addClass "active" if home?

    new_menu_entry: (ctx) ->
      dust.render "_new_menu_entry", ctx, (err, out) =>
        @$el.append(out)

    home: (event) ->
      dispatcher.trigger "home" unless $(event.currentTarget).parent().hasClass "active"

    new: (event) ->
      dispatcher.trigger "new" unless $(event.currentTarget).parent().hasClass "active"

    events:
      "click a[href=#home]": "home"
      "click a[href=#new]": "new"

  class AppView extends Backbone.View

    el: $ "body > .container"

    initialize: () ->
      @navigationView = new NavigationView()

      @presentationList = new PresentationList()

      @presentationList.on "reset", @reset, @

    reset: (model) ->
      @$el.empty()
      view = new PresentationListView model: model
      @$el.html view.render().el

    home: () ->
      @presentationList.fetch()
      @navigationView.reset(true)

  app = new AppView()

  dispatcher = _.clone(Backbone.Events)
  dispatcher.on "home", () ->
    app.home()
  dispatcher.on "new", () ->
    throw new Error("unimplemented")
  dispatcher.on "new_menu_entry", (ctx) ->
    app.navigationView.reset()
    app.navigationView.new_menu_entry(ctx)

  dispatcher.trigger "home"