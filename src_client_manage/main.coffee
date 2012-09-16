jQuery () ->
  prsntz = new Presentz("#video", "460x420", "#slide", "460x420")

  init_presentz = (presentation, first) ->
    prsntz.init presentation
    prsntz.changeChapter 0, 0, false
    return unless first?
    $video = $("#video")
    $video_parent = $video.parent()
    $video.width $video_parent.width()
    $video.height $video_parent.height()

  rebuild_slide_indexes = ($slides) ->
    $slides.each (new_index, elem) ->
      $elem = $(elem)
      $elem.attr("slide_index", new_index)
      $helper.elements_with_slide_index_in($elem).each (idx, subelem) ->
        $(subelem).attr("slide_index", new_index)
      $helper.elements_with_placeholder_in($elem).each (idx, subelem) ->
        $(subelem).attr("placeholder", "Slide #{new_index + 1}")

  video_backends = [new window.video_backends.Youtube(prsntz.availableVideoPlugins.youtube), new window.video_backends.Vimeo(prsntz.availableVideoPlugins.vimeo), new window.video_backends.Dummy(prsntz.availableVideoPlugins.html5)]
  slide_backends = [new window.slide_backends.SlideShare(prsntz.availableSlidePlugins.slideshare), new window.slide_backends.Dummy(prsntz.availableSlidePlugins.image)]

  $helper =
    slide_containers: () -> $("div[slide_index]")
    slide_thumb_container_in: ($elem) -> $("div.slide_thumb", $elem)
    parent_control_group_of: ($elem) -> $elem.parentsUntil("div.control-group").parent()
    video_duration_input_of: (chapter_index) -> $("input[name=video_duration][chapter_index=#{chapter_index}]")

    slides: () -> $("div.slides")
    slide_at: (slide_index) -> $("div.slides div.row-fluid[slide_index=#{slide_index}]")
    current_time: () -> $("span[name=current_time]")
    play_pause_btn: () -> $("a.play_pause_btn")

    chapter: (chapter_index) -> $("#chapter#{chapter_index}")
    video_url_input_of: (chapter_index) -> $("#chapter#{chapter_index} input[name=video_url]")
    video_thumb_input_of: (chapter_index) -> $("#chapter#{chapter_index} input[name=video_thumb]")
    video_thumb_of: (chapter_index) -> $("img[chapter_index=#{chapter_index}]")

    chapter_of: ($elem) -> $elem.parentsUntil("span.chapter").last().parent()
    slide_index_from: ($elem) -> $elem.attr "slide_index"
    chapter_index_from: ($chapter) -> parseInt $chapter.attr("id").substr("chapter".length)
    slide_of: (slide_index, $chapter) -> $("div[slide_index=#{slide_index}]", $chapter)
    slide_thumb_of: (slide_index, $chapter) -> $("div.slide_thumb", @slide_of(slide_index, $chapter))
    slides_of: ($chapter) -> $("div[slide_index]", $chapter)
    elements_with_slide_index_in: ($elem) -> $("[slide_index]", $elem)
    elements_with_placeholder_in: ($elem) -> $("[placeholder]", $elem)

    new_title: () -> $("input[name=title]")

    notify_save_text: ($parent) -> $("li.notify_save", $parent)
    whoops: (message, callback) ->
      $whoops = $("#whoops")
      return $whoops unless message?

      if typeof message is "string"
        $(".modal-body p:first", $whoops).text message
      else
        $(".modal-body p:first", $whoops).text message.message
        $(".modal-body p:last", $whoops).text message.stack

      if callback?
        $whoops.on "hidden", () ->
          $whoops.off "hidden"
          callback()
      $whoops.modal "show"

    confirm: (message, callback) ->
      $confirm = $("#confirm")
      return $confirm unless message?

      $(".modal-body p", $confirm).text(message)
      $(".modal-footer button:last").click callback
      $confirm.modal "show"

    advanced_user: () -> $("#advanced_user")
    advanced_user_data_preview: () -> $("#advanced_user_data_preview")
    slide_burn_confirm: () -> $("#slide_burn_confirm")

    slide_helper: ($elem) ->
      $chapter = $helper.chapter_of $elem
      slide_index = $helper.slide_index_from $elem
      chapter_index = $helper.chapter_index_from $chapter

      result =
        $chapter: $chapter
        slide_index: slide_index
        chapter_index: chapter_index
        model_selector: "chapters.#{chapter_index}.slides.#{slide_index}"
        slide_thumb: () ->
          $helper.slide_thumb_of slide_index, $chapter
      return result

  $helper.whoops().modal(show: false)
  $helper.confirm().modal(show: false)
  $helper.advanced_user().modal(show: false)
  $helper.advanced_user_data_preview().modal(show: false)
  $helper.slide_burn_confirm().modal(show: false)

  alert = (message, callback) ->
    $helper.whoops(message, callback)

  confirm = (message, callback) ->
    $helper.confirm(message, callback)

  class NavigationView extends Backbone.View

    el: $(".navbar > .navbar-inner > .container > .nav-collapse > .nav:first")

    reset: (highlight_idx) ->
      $("li:gt(1)", @$el).remove()
      $("li", @$el).removeClass "active"
      $("li", @$el).eq(highlight_idx).addClass "active" if highlight_idx?

    presentation_menu_title_save_btn: (title, published) ->
      $li = $("li", @$el)
      if $li.length < 3
        $li.removeClass "active"
        dust.render "_presentation_menu_title_save_btn", { title: title, published: published }, (err, out) =>
          return alert(err) if err?

          @$el.append(out)
          $helper.notify_save_text().hide()
          window.views.disable_forms()
      else
        $("a span", $li.eq(2)).text title

    mypres: (event) ->
      router.navigate "mypres", trigger: true unless $(event.currentTarget).parent().hasClass "active"

    make: (event) ->
      router.navigate "make", trigger: true unless $(event.currentTarget).parent().hasClass "active"

    enable_save_button: () ->
      $button = $("button", @$el)
      $button.attr "disabled", false
      $button.removeClass "disabled"
      $button.addClass "btn-warning"

    disable_save_button: () ->
      $button = $("button", @$el)
      $button.attr "disabled", true
      $button.addClass "disabled"
      $button.removeClass "btn-warning"
      $notify_save = $helper.notify_save_text()
      $notify_save.fadeIn "slow", () ->
        $notify_save.fadeOut "slow"

    save: (event) ->
      presentation_id = app.save()
      if $(event.target).hasClass("preview")
        window.open "#{user_catalog}/#{presentation_id}?preview", "preview"

    events:
      "click a[href=#mypres]": "mypres"
      "click a[href=#make]": "make"
      "click button.save": "save"

  class AppView extends Backbone.View

    dirty: false

    el: $ "body > .container"

    initialize: () ->
      _.bindAll(@)

      @navigationView = new NavigationView()

      @presentationThumbList = new window.models.PresentationThumbList()

      @presentationThumbList.on "reset", @reset, @

    reset: (models) ->
      if models.length > 0
        view = new window.views.PresentationThumbListView model: models
        @$el.html view.el
        view.render()
        view.bind "edit", (id) =>
          router.navigate(id, trigger: true)

      else
        dust.render "_no_talks_here", {}, (err, out) =>
          return alert(err) if err?
          @$el.html out
          window.views.disable_forms()

      window.views.loader_hide()

    mypres: () ->
      @clear_dirty()
      window.views.loader_show()
      @presentationThumbList.fetch()
      @navigationView.reset(0)

    make: () ->
      @clear_dirty()
      @navigationView.reset(1)
      view = new window.views.PresentationNewView(video_backends, slide_backends)
      view.render().bind "new", (presentation) =>
        @edit(presentation)
        router.navigate presentation.get("id")
      @$el.html view.el

    presentation: (id) ->
      @clear_dirty()
      window.views.loader_show()
      presentation = new window.models.Presentation({ id: id })
      presentation.bind "change", @edit

    edit: (model) ->
      @clear_dirty()

      model.unbind "change", @edit

      @view = new window.views.PresentationEditView(model: model, video_backends, slide_backends)
      @view.render()
      @view.bind "presentation_title", (title, published) =>
        @navigationView.presentation_menu_title_save_btn utils.cut_string_at(title, 30), published
      @$el.html @view.el

    save: () ->
      @view.save()

    enable_save_button: () ->
      @set_dirty()
      @navigationView.enable_save_button()

    disable_save_button: () ->
      @clear_dirty()
      @navigationView.disable_save_button()

    set_dirty: () ->
      @dirty = true

    clear_dirty: () ->
      @dirty = false

  app = new AppView()
  router = new AppRouter(app)

  $("ul.nav a").click (event) ->
    return true unless app.dirty
    confirm "You have unsaved changes. Are you sure you want to proceed?", () ->
      window.location.hash = event.target.hash
    false

  Backbone.history.start pushState: false, root: "/m/"
  $.jsonp.setup callbackParameter: "callback"
  