jQuery () ->
  class Presentation extends Backbone.DeepModel

    urlRoot: "/m/api/presentations/"

    initialize: () ->
      _.bindAll @

      @bind "change", app.edit, app

      @fetch()

  class PresentationEditView extends Backbone.View

    tagName: "div"

    render: () ->
      dust.render "_presentation", @model.attributes, (err, out) =>
        dispatcher.trigger "hide_loader"
        @$el.append(out)
      @

  class PresentationThumb extends Backbone.DeepModel

  class PresentationThumbView extends Backbone.View

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
        dispatcher.trigger "hide_loader"
        @$el.html out
      @

    toogle_published: () ->
      @model.set "published", !@model.get "published"
      @model.save()
      false

    edit: () ->
      dispatcher.trigger "new_menu_entry", title: utils.cut_string_at(@model.get("title"), 30)
      dispatcher.trigger "edit", @model.get("id")
      false

    events:
      "click a.publish": "toogle_published"
      "click a.edit": "edit"

  class PresentationThumbList extends Backbone.Collection

    url: "/m/api/presentations"

    model: PresentationThumb

    comparator: (presentation) ->
      presentation.get("title")

  class PresentationThumbListView extends Backbone.View

    tagName: "ul"

    className: "thumbnails"

    render: () ->
      @model.each (model) =>
        view = new PresentationThumbView model: model
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

      @presentationThumbList = new PresentationThumbList()

      @presentationThumbList.on "reset", @reset, @

    reset: (model) ->
      view = new PresentationThumbListView model: model
      @$el.html view.render().el

    home: () ->
      @presentationThumbList.fetch()
      @navigationView.reset(true)

    edit: (model) ->
      view = new PresentationEditView model: model
      @$el.html view.render().el
      presentz = new Presentz("#video", "460x420", "#slide", "460x420")
      presentz.init model.attributes
      presentz.changeChapter 0, 0, false

  app = new AppView()

  loader_shown = true

  dispatcher = _.clone(Backbone.Events)

  dispatcher.on "home", () ->
    dispatcher.trigger "show_loader"
    app.home()

  dispatcher.on "new", () ->
    dispatcher.trigger "show_loader"
    throw new Error("unimplemented")

  dispatcher.on "new_menu_entry", (ctx) ->
    app.navigationView.reset()
    app.navigationView.new_menu_entry ctx

  dispatcher.on "edit", (id) ->
    dispatcher.trigger "show_loader"
    presentation = new Presentation({ id: id })

  dispatcher.on "hide_loader", () ->
    if loader_shown
      $("div.loader").hide()
      loader_shown = false

  dispatcher.on "show_loader", () ->
    if !loader_shown
      $("body > .container").empty()
      $("div.loader").show()
      loader_shown = true

  dispatcher.trigger "home"