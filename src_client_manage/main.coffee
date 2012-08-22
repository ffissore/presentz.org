@presentzorg = {}

jQuery () ->
  presentz = new Presentz("#video", "460x420", "#slide", "460x420")

  init_presentz = (presentation, first) ->
    presentz.init presentation
    presentz.changeChapter 0, 0, false
    return unless first?
    $video = $("#video")
    $video_parent = $video.parent()
    $video.width $video_parent.width()
    $video.height $video_parent.height()

  presentzorg = window.presentzorg
  video_backends = [new presentzorg.video_backends.Youtube(), new presentzorg.video_backends.Vimeo(), new presentzorg.video_backends.DummyVideoBackend()]

  class Presentation extends Backbone.DeepModel

    urlRoot: "/m/api/presentations/"

    initialize: () ->
      _.bindAll @

      @bind "change", app.edit, app
      @bind "all", () ->
        console.log arguments

      @fetch()

  class PresentationEditView extends Backbone.View

    tagName: "div"

    render: () ->
      ctx = @model.attributes
      ctx.onebased = dustjs_helpers.onebased

      dust.render "_presentation", ctx, (err, out) =>
        return alert(err) if err?

        loader_hide()
        new_menu_entry title: utils.cut_string_at(@model.get("title"), 30)
        @$el.append(out)
      @

    onchange_video_url: (event) ->
      $elem = $(event.target)
      url = $elem.val()
      backend = _.find video_backends, (backend) -> backend.handle(url)
      return unless backend?
      backend.fetch_info url, (err, info) =>
        $container = $elem.parentsUntil("fieldset", "div.control-group")
        # TODO give this thing an awesome name!
        $next = $elem.next()
        if err?
          $container.addClass "error"
          dust.render "_help_inline", { text: "Invalid URL"}, (err, out) ->
            return alert(err) if err?

            $next.html out
        else
          $container.removeClass "error"
          chapter_index = $elem.attr("chapter_index")
          @model.set "chapters.#{chapter_index}.video.url", info.url
          @model.set "chapters.#{chapter_index}.duration", info.duration
          $("input[name=video_duration][chapter_index=#{chapter_index}]").val info.duration
          init_presentz @model.attributes
          if info.thumb?
            dust.render "_reset_thumb", {}, (err, out) ->
              return alert(err) if err?

              $next.html out
          else
            $next.empty()
      false

    reset_video_thumb: (event) ->
      $elem = $(event.target)
      $button_container = $elem.parent()
      video_url = $button_container.prev().val()
      backend = _.find video_backends, (backend) -> backend.handle(video_url)
      return unless backend?
      backend.fetch_info video_url, (err, info) =>
        return alert(err) if err?

        $container = $elem.parents("div.row-fluid")
        $thumb_input = $("input[name=video_thumb]", $container)
        $thumb_input.val info.thumb
        $thumb_input.change()

        chapter_index = $thumb_input.attr("chapter_index")
        @model.set "chapters.#{chapter_index}.video.thumb", info.thumb
        $("img.thumb[chapter_index=#{chapter_index}]").attr "src", info.thumb

        $button_container.empty()
      false

    onchange_video_thumb_url: (event) ->
      $elem = $(event.target)
      $next = $elem.next()
      $container = $elem.parentsUntil("fieldset", "div.control-group")
      if presentzorg.is_url_valid $elem.val()
        $container.removeClass "error"
        $next.empty()
        chapter_index = $elem.attr("chapter_index")
        @model.set "chapters.#{chapter_index}.video.thumb", $elem.val()
        $("img.thumb[chapter_index=#{chapter_index}]").attr "src", $elem.val()
      else
        $container.addClass "error"
        dust.render "_help_inline", { text: "Invalid URL"}, (err, out) ->
          return alert(err) if err?

          $next.html out
      false

    onchange_title: (event) ->
      title = $(event.target).val()
      @model.set "title", title
      $("ul.nav li.active a").text utils.cut_string_at title, 30

    events:
      "change input[name=video_url]": "onchange_video_url"
      "click button.reset_thumb": "reset_video_thumb"
      "change input[name=video_thumb]": "onchange_video_thumb_url"
      "change input.title-input": "onchange_title"

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
        return alert(err) if err?

        loader_hide()
        @$el.html out
      @

    toogle_published: () ->
      @model.set "published", !@model.get "published"
      @model.save()
      false

    edit: () ->
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
        return alert(err) if err?

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
      presentz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
        $("div[chapter_index=#{previous_chapter_index}] ~ div[slide_index=#{previous_slide_index}]").removeClass "alert alert-info"
        $("div[chapter_index=#{new_chapter_index}] ~ div[slide_index=#{new_slide_index}]").addClass "alert alert-info"
      init_presentz model.attributes, true
      model.unbind "change", @edit

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
      alert("unimplemented")

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
  $.jsonp.setup callbackParameter: "callback"