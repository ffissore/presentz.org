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
  slide_backends = [new presentzorg.slide_backends.SlideShare(), new presentzorg.slide_backends.DummySlideBackend()]

  $helper =
    slide_containers: () -> $("div[slide_index]")
    slide_thumb_container_in: ($elem) -> $("div.slide_thumb", $elem)
    parent_control_group_of: ($elem) -> $elem.parentsUntil("div.control-group").parent()
    video_duration_input_of: (chapter_index) -> $("input[name=video_duration][chapter_index=#{chapter_index}]")

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

    notify_save_text: ($parent) -> $("li.notify_save", $parent)
    whoops: (err, callback) ->
      $whoops = $("#whoops")
      return $whoops if !err?

      if typeof err is "string"
        $(".modal-body p:first", $whoops).text err
      else
        $(".modal-body p:first", $whoops).text err.message
        $(".modal-body p:last", $whoops).text err.stack

      if callback?
        $whoops.on "hidden", () ->
          $whoops.off "hidden"
          callback()
      $whoops.modal "show"

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

  alert = (err, callback) ->
    $helper.whoops(err, callback)

  class Presentation extends Backbone.DeepModel

    keys_to_remove_on_save = [ "onebased", "$idx", "$len", "_plugin" ]

    urlRoot: "/m/api/presentations/"

    validate: presentzorg.validation

    loaded: false

    toJSON: () ->
      presentation = $.extend true, {}, @attributes

      utils.visit_presentation presentation, utils.remove_unwanted_fields_from, keys_to_remove_on_save

      return presentation

    initialize: () ->
      _.bindAll @

      @bind "change", app.edit, app
      @bind "error", (model, err) ->
        alert "Error #{err.status}: #{err.responseText}"
      @bind "all", (event) =>
        if @loaded and _.str.startsWith(event, "change")
          app.navigationView.enable_save_button()
        if @loaded and event is "sync"
          app.navigationView.disable_save_button()
        if event is "change"
          @loaded = true
        console.log arguments

      @fetch()

  class PresentationEditView extends Backbone.View

    tagName: "div"

    render: () ->
      ctx = @model.attributes
      ctx.onebased = dustjs_helpers.onebased

      slides = []
      for chapter in @model.attributes.chapters
        for slide in chapter.slides
          slides.push slide

      load_slides_info = (slides) =>
        slide = slides.pop()
        backend = _.find slide_backends, (backend) -> backend.handle(slide.url)
        slide._thumb_type = backend.thumb_type_of slide.url
        backend.slide_info slide, (err, slide, slide_info) =>
          return alert(err) if err?
          slide.public_url ||= slide_info.public_url
          slide.number ||= slide_info.number if slide_info.number?
          slide.slide_thumb ||= slide_info.slide_thumb if slide_info.slide_thumb?

          if slides.length > 0
            load_slides_info slides
          else
            dust.render "_presentation", ctx, (err, out) =>
              return alert(err) if err?

              loader_hide()
              app.navigationView.presentation_menu_entry utils.cut_string_at(@model.get("title"), 30)
              @$el.append(out)
              init_presentz @model.attributes, true
              $helper.slide_containers().scrollspy
                buffer: app.navigationView.$el.height()
                onEnter: ($elem) ->
                  $slide_thumb = $helper.slide_thumb_container_in $elem
                  dust.render "_#{$slide_thumb.attr "thumb_type"}_slide_thumb", { slide_thumb: $slide_thumb.attr "src" }, (err, out) ->
                    return alert(err) if err?
                    $slide_thumb.html out
                onLeave: ($elem) ->
                  $slide_thumb = $helper.slide_thumb_container_in $elem
                  $slide_thumb.empty()

      load_slides_info slides
      @

    onchange_video_url: (event) ->
      $elem = $(event.target)
      url = $elem.val()
      backend = _.find video_backends, (backend) -> backend.handle(url)
      backend.fetch_info url, (err, info) =>
        $parent_control_group = $helper.parent_control_group_of $elem
        $video_url_error_msg_container = $elem.next()
        if err?
          $parent_control_group.addClass "error"
          dust.render "_help_inline", { text: "Invalid URL"}, (err, out) ->
            return alert(err) if err?

            $video_url_error_msg_container.html out
        else
          $parent_control_group.removeClass "error"
          chapter_index = $elem.attr("chapter_index")
          @model.set "chapters.#{chapter_index}.video.url", info.url
          @model.set "chapters.#{chapter_index}.duration", info.duration
          $helper.video_duration_input_of(chapter_index).val info.duration
          init_presentz @model.attributes
          if info.thumb?
            dust.render "_reset_thumb", { chapter_index: chapter_index }, (err, out) ->
              return alert(err) if err?

              $video_url_error_msg_container.html out
          else
            $video_url_error_msg_container.empty()
      false

    reset_video_thumb: (event) ->
      $elem = $(event.target)
      chapter_index = parseInt $elem.attr("chapter_index")
      video_url = $helper.video_url_input_of(chapter_index).val()

      backend = _.find video_backends, (backend) -> backend.handle(video_url)
      backend.fetch_info video_url, (err, info) =>
        return alert(err) if err?

        $thumb_input = $helper.video_thumb_input_of(chapter_index)
        $thumb_input.val info.thumb
        $thumb_input.change()

        @model.set "chapters.#{chapter_index}.video.thumb", info.thumb
        $helper.video_thumb_of(chapter_index).attr "src", info.thumb

        $elem.parent().empty()
      false

    onchange_video_thumb_url: (event) ->
      $elem = $(event.target)
      thumb_url = $elem.val()
      $video_thumb_error_msg_container = $elem.next()
      $container = $helper.parent_control_group_of($elem)

      if presentzorg.is_url_valid thumb_url
        $container.removeClass "error"
        $video_thumb_error_msg_container.empty()
        chapter_index = $elem.attr("chapter_index")
        @model.set "chapters.#{chapter_index}.video.thumb", thumb_url
        $helper.video_thumb_of(chapter_index).attr "src", thumb_url
      else
        $container.addClass "error"
        dust.render "_help_inline", { text: "Invalid URL"}, (err, out) ->
          return alert(err) if err?

          $video_thumb_error_msg_container.html out
      false

    onchange_title: (event) ->
      title = $(event.target).val()
      @model.set "title", title
      app.navigationView.presentation_menu_entry utils.cut_string_at(@model.get("title"), 30)

    onchange_slide_title: (event) ->
      $elem = $(event.target)
      slide_helper = $helper.slide_helper $elem

      @model.set "#{slide_helper.model_selector}.title", $elem.val()

    onchange_slide_number: (event) ->
      $elem = $(event.target)
      slide_helper = $helper.slide_helper $elem

      slide = @model.get slide_helper.model_selector
      backend = _.find slide_backends, (backend) -> backend.handle(slide.url)

      new_url = backend.change_slide_number slide.url, $elem.val()
      @model.set "#{slide_helper.model_selector}.url", new_url

      backend.slide_info slide, (err, slide, slide_info) =>
        if err?
          alert err, () ->
            $elem.focus()
          return
        slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?
        $slide_thumb = slide_helper.slide_thumb()
        $slide_thumb.attr "src", slide.slide_thumb
        dust.render "_#{$slide_thumb.attr "thumb_type"}_slide_thumb", { slide_thumb: $slide_thumb.attr "src" }, (err, out) ->
          return alert(err) if err?
          $slide_thumb.html out

    onchange_slide_time: (event) ->
      $elem = $(event.target)
      slide_helper = $helper.slide_helper $elem

      slide = @model.get slide_helper.model_selector
      backend = _.find slide_backends, (backend) -> backend.handle(slide.url)

      @model.set "#{slide_helper.model_selector}.time", Math.round($elem.val())

      slides = @model.get "chapters.#{slide_helper.chapter_index}.slides"
      source_index = slides.indexOf slide
      slides = _.sortBy slides, (slide) -> slide.time
      dest_index = slides.indexOf slide
      return if source_index is dest_index

      @model.set "chapters.#{slide_helper.chapter_index}.slides", slides

      $source_element = $helper.slide_of source_index, slide_helper.$chapter
      $dest_element = $helper.slide_of dest_index, slide_helper.$chapter
      if dest_index < source_index
        $source_element.insertBefore $dest_element
      else
        $source_element.insertAfter $dest_element

      $helper.slides_of(slide_helper.$chapter).each (current_index, element) ->
        $elem = $(element)
        $elem.attr "slide_index", current_index
        $helper.elements_with_slide_index_in($elem).each (idx, element) ->
          $(element).attr "slide_index", current_index

    onchange_slide_public_url: (event) ->
      $elem = $(event.target)
      public_url = $elem.val()
      return if !presentzorg.is_url_valid public_url

      slide_helper = $helper.slide_helper $elem

      @model.set "#{slide_helper.model_selector}.public_url", public_url

      backend = _.find slide_backends, (backend) -> backend.handle(public_url)
      slide = @model.get slide_helper.model_selector

      backend.url_from_public_url slide, (new_url) =>
        @model.set "#{slide_helper.model_selector}.url", new_url

        backend.slide_info slide, (err, slide, slide_info) =>
          return alert(err) if err?
          slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?
          $slide_thumb = slide_helper.slide_thumb()
          $slide_thumb.attr "src", slide.slide_thumb
          $slide_thumb.attr "thumb_type", backend.thumb_type_of slide.url
          dust.render "_#{$slide_thumb.attr "thumb_type"}_slide_thumb", { thumb: $slide_thumb.attr "src" }, (err, out) ->
            return alert(err) if err?
            $slide_thumb.html out

    save: () ->
      @model.save()

    events:
      "change input[name=video_url]": "onchange_video_url"
      "click button.reset_thumb": "reset_video_thumb"
      "change input[name=video_thumb]": "onchange_video_thumb_url"
      "change input.title-input": "onchange_title"

      "change input.slide_number": "onchange_slide_number"
      "change input.slide_title": "onchange_slide_title"
      "change input.slide_time": "onchange_slide_time"
      "change input.slide_public_url": "onchange_slide_public_url"

  class PresentationThumb extends Backbone.DeepModel

    initialize: () ->
      _.bindAll @

      @bind "all", () ->
        console.log arguments

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

  class PresentationNewView extends Backbone.View

    tagName: "div"

    render: () ->
      dust.render "_new", {}, (err, out) =>
        return alert(err) if err?
        loader_hide()
        @$el.html(out)
    
  class NavigationView extends Backbone.View

    el: $(".navbar > .navbar-inner > .container > .nav-collapse > .nav")

    reset: (highlight_idx) ->
      $("li:gt(1)", @$el).remove()
      $("li", @$el).removeClass "active"
      $("li", @$el).eq(highlight_idx).addClass "active" if highlight_idx?

    presentation_menu_entry: (title) ->
      $li = $("li", @$el)
      if $li.length < 3
        $li.removeClass "active"
        dust.render "_presentation_menu_entry", { title: title }, (err, out) =>
          return alert(err) if err?

          @$el.append(out)
          $helper.notify_save_text().hide()
      else
        $("a", $li.eq(2)).text title

    home: (event) ->
      router.navigate "home", trigger: true unless $(event.currentTarget).parent().hasClass "active"

    new: (event) ->
      router.navigate "new", trigger: true unless $(event.currentTarget).parent().hasClass "active"

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

    save: () ->
      app.save()

    events:
      "click a[href=#home]": "home"
      "click a[href=#new]": "new"
      "click button.save": "save"

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
      @navigationView.reset(0)
      
    new: () ->
      @navigationView.reset(1)
      view = new PresentationNewView()
      @$el.html view.el
      view.render()

    edit: (model) ->
      @view = new PresentationEditView model: model
      @$el.html @view.el
      @view.render()
      presentz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
        $("div[chapter_index=#{previous_chapter_index}] ~ div[slide_index=#{previous_slide_index}]").removeClass "alert alert-info"
        $("div[chapter_index=#{new_chapter_index}] ~ div[slide_index=#{new_slide_index}]").addClass "alert alert-info"
      model.unbind "change", @edit

    save: () ->
      @view.save()

  app = new AppView()

  class AppRouter extends Backbone.Router

    routes:
      "": "go_home"
      "home": "home"
      "new": "new"
      ":presentation": "presentation"

    go_home: () ->
      @navigate "home", trigger: true

    home: () ->
      loader_show()
      app.home()

    new: () ->
      app.new()

    presentation: (id) ->
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

  Backbone.history.start pushState: false, root: "/m/"
  $.jsonp.setup callbackParameter: "callback"
  