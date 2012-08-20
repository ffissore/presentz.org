jQuery () ->
  class Presentation extends Backbone.DeepModel

    urlRoot: "/m/api/presentations/"

    initialize: () ->
      _.bindAll @

      @bind "change", app.edit, app

      @fetch()

  class PresentationEditVideoView extends Backbone.View


  class PresentationEditView extends Backbone.View

    tagName: "div"

    render: () ->
      ctx = @model.attributes
      ctx.onebased = dustjs_helpers.onebased

      dust.render "_presentation", ctx, (err, out) =>
        loader_hide()
        new_menu_entry title: utils.cut_string_at(@model.get("title"), 30)
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
        loader_hide()
        @$el.html out
      @

    toogle_published: () ->
      @model.set "published", !@model.get "published"
      @model.save()
      false

    edit: () ->
      #new_menu_entry title: utils.cut_string_at(@model.get("title"), 30)
      router.navigate @model.get("id"), trigger: true
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
        @$el.append view.el
        view.render()
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
      router.navigate "home", trigger: true unless $(event.currentTarget).parent().hasClass "active"

    new: (event) ->
      router.navigate "new", trigger: true unless $(event.currentTarget).parent().hasClass "active"

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
      @$el.html view.el
      view.render()

    home: () ->
      @presentationThumbList.fetch()
      @navigationView.reset(true)

    edit: (model) ->
      view = new PresentationEditView model: model
      @$el.html view.el
      view.render()
      presentz = new Presentz("#video", "460x420", "#slide", "460x420")
      presentz.init model.attributes
      presentz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
        $("div[chapter_index=#{previous_chapter_index}] ~ div[slide_index=#{previous_slide_index}]").removeClass "alert alert-info"
        $("div[chapter_index=#{new_chapter_index}] ~ div[slide_index=#{new_slide_index}]").addClass "alert alert-info"
      presentz.changeChapter 0, 0, false

  app = new AppView()

  class AppRouter extends Backbone.Router

    routes:
      "": "go_home"
      "home": "home"
      "new": "new"
      ":presentation": "edit"

    go_home: () ->
      @navigate "home", trigger: true

    home: () ->
      loader_show()
      app.home()

    new: () ->
      loader_show()
      throw new Error("unimplemented")

    edit: (id) ->
      loader_show()
      presentation = new Presentation({ id: id })

  router = new AppRouter()

  loader_shown = true

  loader_hide = () ->
    if loader_shown
      $("div.loader").hide()
      loader_shown = false

  loader_show = () ->
    if !loader_shown
      $("body > .container").empty()
      $("div.loader").show()
      loader_shown = true

  new_menu_entry = (ctx) ->
    app.navigationView.reset()
    app.navigationView.new_menu_entry ctx

  Backbone.history.start pushState: false, root: "/m/"