@presentzorg = {}

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

  video_backends = [new presentzorg.video_backends.Youtube(prsntz.availableVideoPlugins.youtube), new presentzorg.video_backends.Vimeo(prsntz.availableVideoPlugins.vimeo), new presentzorg.video_backends.DummyVideoBackend(prsntz.availableVideoPlugins.html5)]
  slide_backends = [new presentzorg.slide_backends.SlideShare(prsntz.availableSlidePlugins.slideshare), new presentzorg.slide_backends.DummySlideBackend(prsntz.availableSlidePlugins.image)]

  $helper =
    scroll_top: () -> $(window).scrollTop(0)
    slide_containers: () -> $("div[slide_index]")
    slide_thumb_container_in: ($elem) -> $("div.slide_thumb", $elem)
    parent_control_group_of: ($elem) -> $elem.parentsUntil("div.control-group").parent()
    video_duration_input_of: (chapter_index) -> $("input[name=video_duration][chapter_index=#{chapter_index}]")

    slides: () -> $("div.slides")
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
    slide_burn_confirm: () -> $("div.slide_burn_confirm")

    new_title: () -> $("input[name=title]")

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

    advanced_user: () -> $("#advanced_user")
    advanced_user_data_preview: () -> $("#advanced_user_data_preview")

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
  $helper.advanced_user().modal(show: false)
  $helper.advanced_user_data_preview().modal(show: false)

  alert = (err, callback) ->
    $helper.whoops(err, callback)

  class Presentation extends Backbone.DeepModel

    urlRoot: "/m/api/presentations/"

    validate: presentzorg.validation

    loaded: false
    loading: false
    slides_to_delete: []

    toJSON: () ->
      presentation = $.extend true, {}, @attributes

      utils.visit_presentation presentation, utils.remove_unwanted_fields_from, [ "onebased", "$idx", "$len", "_plugin" ]

      return presentation

    delete_slides = (slides, callback) ->
      return callback() if !slides? or slides.length is 0

      slide = slides.pop()

      delete_slides(slides, callback) unless slide["@rid"]?

      $.ajax
        type: "DELETE"
        url: "/m/api/delete_slide/#{slide["@rid"].substr(1)}"
        success: () ->
          delete_slides(slides, callback)
        error: () ->
          alert("An error occured while deleting the slides")

    save: (attributes, options) ->
      options ||= {}
      options.success = (model, resp) =>
        if @slides_to_delete.length is 0
          return @trigger("sync", model, resp)

        delete_slides @slides_to_delete, () =>
          @loading = false
          @loaded = false
          @fetch { success: () => @trigger("sync") }

      Backbone.DeepModel.prototype.save.call(this, attributes, options)

    initialize: () ->
      _.bindAll @

      @bind "change", () ->
        app.edit(@) if !@loading
        @loading = true

      @bind "error", (model, error) ->
        if _.isString(error)
          alert error
        else if error.status?
          alert "Error: (#{error.status}): #{error.responseText}"
        else if error.message?
          alert "Error: #{error.message}"
      @bind "all", (event) =>
        if @loaded and _.str.startsWith(event, "change")
          app.navigationView.enable_save_button()
        if @loaded and event is "sync"
          app.navigationView.disable_save_button()
        if event is "change"
          @loaded = true
        console.log arguments

      keys = (key for key, value of @attributes)

      if keys.length is 1 and keys[0] is "id"
        @fetch()
      else
        @set "id", utils.generate_id(@get("title"))
        @set "@class", "V"
        @set "@type", "d"
        @set "_type", "presentation"
        for chapter, chapter_idx in @get("chapters")
          @set "chapters.#{chapter_idx}.@class", "V"
          @set "chapters.#{chapter_idx}.@type", "d"
          @set "chapters.#{chapter_idx}._type", "chapter"
          @set "chapters.#{chapter_idx}._index", chapter_idx
          for slide, slide_idx in @get("chapters.#{chapter_idx}.slides")
            @set "chapters.#{chapter_idx}.slides.#{slide_idx}.@class", "V"
            @set "chapters.#{chapter_idx}.slides.#{slide_idx}.@type", "d"
            @set "chapters.#{chapter_idx}.slides.#{slide_idx}._type", "chapter"

  class PresentationEditView extends Backbone.View

    tagName: "div"

    render: () ->
      $helper.scroll_top()
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
          slide.public_url = slide_info.public_url
          slide.number = slide_info.number if slide_info.number?
          slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?

          if slides.length > 0
            load_slides_info slides
          else
            dust.render "_presentation", ctx, (err, out) =>
              return alert(err) if err?

              loader_hide()
              app.navigationView.presentation_menu_entry utils.cut_string_at(@model.get("title"), 30), @model.get("published")
              @$el.html(out)

              $("input[name=time]").datepicker { dateFormat: "yymmdd" }

              $helper.slides().movingBoxes
                startPanel: 1
                reducedSize: 0.8
                wrap: false
                buildNav: true
                hashTags: false
                fixedHeight: true
                navFormatter: (idx) -> "#{idx}"
                initAnimation: false
                stopAnimation: true
                completed: (base, curPanel) ->
                  for $elem in $helper.slide_containers()
                    $slide_thumb = $helper.slide_thumb_container_in $elem
                    $slide_thumb.empty()

                  $slide_thumb = $helper.slide_thumb_container_in curPanel.$curPanel
                  dust.render "_#{$slide_thumb.attr "thumb_type"}_slide_thumb", { slide_thumb: $slide_thumb.attr "src" }, (err, out) ->
                    return alert(err) if err?
                    $slide_thumb.html out

              init_presentz @model.attributes, true

      load_slides_info slides
      @

    onchange_simple_field: (fieldname, event) ->
      $elem = $(event.target)
      value = $.trim($elem.val())
      if value is ""
        @model.unset fieldname
      else
        @model.set fieldname, $elem.val()

    onchange_speaker: (event) ->
      @onchange_simple_field("speaker", event)

    onchange_time: (event) ->
      @onchange_simple_field("time", event)

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

    onchange_video_duration: (event) ->
      $elem = $(event.target)
      chapter_index = $elem.attr("chapter_index")
      @model.set("chapters.#{chapter_index}.duration", parseInt($elem.val()))
      false

    onchange_video_thumb_url: (event) ->
      $elem = $(event.target)
      thumb_url = $elem.val()
      $video_thumb_error_msg_container = $elem.next()
      $container = $helper.parent_control_group_of($elem)

      if utils.is_url_valid thumb_url
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
      app.navigationView.presentation_menu_entry utils.cut_string_at(@model.get("title"), 30), @model.get("published")

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
      return if !utils.is_url_valid public_url

      slide_helper = $helper.slide_helper $elem

      @model.set "#{slide_helper.model_selector}.public_url", public_url

      backend = _.find slide_backends, (backend) -> backend.handle(public_url)
      slide = @model.get slide_helper.model_selector

      backend.url_from_public_url slide, (err, new_url) =>
        return alert(err) if err?
        @model.set "#{slide_helper.model_selector}.url", new_url

        backend.slide_info slide, (err, slide, slide_info) =>
          return alert(err) if err?
          slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?
          $slide_thumb = slide_helper.slide_thumb()
          $slide_thumb.attr "src", slide.slide_thumb
          $slide_thumb.attr "thumb_type", backend.thumb_type_of slide.url
          dust.render "_#{$slide_thumb.attr "thumb_type"}_slide_thumb", { slide_thumb: $slide_thumb.attr "src" }, (err, out) ->
            return alert(err) if err?
            $slide_thumb.html out

    save: () ->
      @model.save()

    onclick_playpause: (event) ->
      $btn = $(event.target)
      if prsntz.isPaused()
        prsntz.play()
        $btn.removeClass("play").addClass("pause")
      else
        prsntz.pause()
        $btn.removeClass("pause").addClass("play")
      false

    onclick_advanced_user: () ->
      $helper.advanced_user_data_preview().modal "hide"
      $helper.advanced_user().modal "show"
      false

    onchange_slide_times_file: (event) ->
      return if !event.target.files or event.target.files.length is 0

      file = event.target.files[0]
      if file.type not in ["text/plain", "text/csv"]
        alert("Only plain text or CSV files are supported")
        return

      reader = new FileReader()
      reader.onload = (load) =>
        text = load.target.result.replace(/\r/g, "\n")
        while text.indexOf(/\n\n/) isnt -1
          text = text.replace(/\n\n/g, "\n")

        rows = text.split(/\n/)
        @data = []
        for row in rows
          match = /(.+),(.+)/.exec(row)
          if match? and match.length >= 3
            @data.push time: parseInt(match[1]), value: match[2]

        $helper.advanced_user().modal("hide")
        $helper.advanced_user_data_preview().modal("show")
        first_slide_url = @model.get("chapters.0.slides.0.url")
        backend = _.find slide_backends, (backend) -> backend.handle(first_slide_url)

        dust.render "_slide_times_preview", { value_type: backend.import_file_value_column, data: @data }, (err, out) ->
          return alert(err) if err?
          $(".modal-body", $helper.advanced_user_data_preview()).html(out)

      reader.readAsText(file)

    onclick_confirm_data_import: () ->
      slides = @model.get("chapters.0.slides")
      check_import_data = (callback) =>
        checked = 0
        for slide, idx in slides when idx < @data.length
          data_for_slide = @data[idx]
          backend = _.find slide_backends, (backend) -> backend.handle(slide.url)
          backend.check_slide_value_from_import slide, data_for_slide.value, (err) =>
            return callback(err) if err?
            checked++
            return callback() if checked is @data.length

      check_import_data (err) ->
        if err?
          $helper.advanced_user_data_preview().modal("hide")
          alert(err)
          return

        for slide, idx in slides when idx < @data.length
          data_for_slide = @data[idx]
          slide.time = data_for_slide.time
          backend = _.find slide_backends, (backend) -> backend.handle(slide.url)
          backend.set_slide_value_from_import(slide, data_for_slide.value)

        @model.set("chapters.0.slides", slides)
        $helper.advanced_user_data_preview().modal("hide")
        @render()

    onclick_slide_burn: (event) ->
      $helper.slide_burn_confirm().remove()

      $elem = $(event.target)
      $slide_container = $elem.parentsUntil("div.row-fluid[slide_index]").last().parent()
      slide_index = $slide_container.attr("slide_index")
      chapter_index = $helper.chapter_index_from($helper.chapter_of($elem))
      dust.render "_confirm_slide_burn", { chapter_index: chapter_index, slide_index: slide_index }, (err, out) ->
        return alert(err) if err?

        $slide_container.before(out)
      false

    onclick_slide_burn_confirmed: (event) ->
      $elem = $(event.target)
      $helper.slide_burn_confirm().remove()

      chapter_index = $elem.attr("chapter_index")
      slide_index = $elem.attr("slide_index")

      chapter = @model.get("chapters.#{chapter_index}")
      slides = @model.get("chapters.#{chapter_index}.slides")
      deleted_slide = slides.splice(slide_index, 1)[0]

      @model.set("chapters.#{chapter_index}.slides", slides)
      @model.slides_to_delete.push deleted_slide

      @render()

      false

    onclick_slide_burn_cancelled: (event) ->
      $helper.slide_burn_confirm().remove()
      false

    onclick_set_time: (event) ->
      slide_index = $helper.slides().getMovingBoxes().curPanel - 1
      slide_time = utils.my_parse_float($helper.current_time().text())
      @model.set("chapters.0.slides.#{slide_index}.time", slide_time)
      $("input.slide_time", $helper.slide_of(slide_index, $helper.chapter(0))).val(slide_time)
      false

    events:
      "click a.play_pause_btn": "onclick_playpause"
      "click a.set_time_btn": "onclick_set_time"
      "click a.hei_advanced": "onclick_advanced_user"
      "click #advanced_user_data_preview button.btn-danger": "onclick_advanced_user"
      "click #advanced_user_data_preview button.btn-success": "onclick_confirm_data_import"
      "change input[type=file]": "onchange_slide_times_file"

      "change input[name=speaker]": "onchange_speaker"
      "change input[name=time]": "onchange_time"
      "change input[name=video_url]": "onchange_video_url"
      "click button.reset_thumb": "reset_video_thumb"
      "change input[name=video_duration]": "onchange_video_duration"
      "change input[name=video_thumb]": "onchange_video_thumb_url"
      "change input.title-input": "onchange_title"

      "change input.slide_number": "onchange_slide_number"
      "change input.slide_title": "onchange_slide_title"
      "change input.slide_time": "onchange_slide_time"
      "change input.slide_public_url": "onchange_slide_public_url"

      "click a.slide_burn": "onclick_slide_burn"
      "click div.slide_burn_confirm a[slide_index][chapter_index]": "onclick_slide_burn_confirmed"
      "click div.slide_burn_confirm .btn-danger": "onclick_slide_burn_cancelled"

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
      presentation.get("title").toLowerCase()

  class PresentationThumbListView extends Backbone.View

    tagName: "ul"

    className: "thumbnails"

    render: () ->
      $helper.scroll_top()
      @model.each (model) =>
        view = new PresentationThumbView model: model
        @$el.append view.el
        view.render()
      @

  class PresentationNewView extends Backbone.View

    tagName: "div"

    @video: null
    @slideshow: null
    @title: null

    render: () ->
      $helper.scroll_top()
      dust.render "_new", {}, (err, out) =>
        return alert(err) if err?
        loader_hide()
        @$el.html(out)

    check_if_time_to_start: () ->
      $button = $("button", @$el)
      if @video? and @slideshow?
        $button.removeClass("disabled")
        $button.attr("disabled", false)
      else
        $button.addClass("disabled")
        $button.attr("disabled", true)

    onchange_video: (event) ->
      $elem = $(event.target)
      url = $elem.val()
      $thumb_container = $(".video_thumb", @$el)
      $thumb_container.empty()
      $thumb_container.append("Fetching info...")
      backend = _.find video_backends, (backend) -> backend.handle(url)
      backend.fetch_info url, (err, info) =>
        $thumb_container.empty()
        @video = null
        if err?
          $thumb_container.append("<div class=\"alert alert-error\">This URL does not look good</div>")
          return
        feedback = "<p>Looks good!"
        if info.thumb?
          feedback = feedback.concat(" Here is the thumb.</p><img class=\"smallthumb\" src=\"#{info.thumb}\"/>")
        else
          feedback = feedback.concat(" At least the URL is well made. Hope there is a real video there.</p>")
        $thumb_container.append(feedback)
        @video = info
        @check_if_time_to_start()

    onchange_slide: (event) ->
      $elem = $(event.target)
      url = $elem.val()
      $thumb_container = $(".slide_thumb", @$el)
      $thumb_container.empty()
      $thumb_container.append("Fetching info...")
      #backend = _.find slide_backends, (backend) -> backend.handle(url)
      #only slideshare
      backend = slide_backends[0]
      backend.slideshow_info url, (err, slide, slideshow_info) =>
        $thumb_container.empty()
        @slideshow = null
        if err?
          $thumb_container.append("<div class=\"alert alert-error\">This URL does not look good</div>")
          return
        $thumb_container.append("<p>Looks good! Here is the first slide.</p>")
        @slideshow = slideshow_info
        @check_if_time_to_start()
        thumb_type = backend.thumb_type_of(slideshow_info.slide_thumb)
        dust.render "_#{thumb_type}_slide_thumb", slideshow_info, (err, out) ->
          return alert(err) if err?
          $thumb_container.append(out)

        $title = $helper.new_title()
        if slideshow_info.title? and $title.val() is ""
          $title.val(slideshow_info.title)
          $title.change()

    onchange_title: (event) ->
      $elem = $(event.target)
      @title = $elem.val()

    onclick_start: () ->
      backend = _.find slide_backends, (backend) => backend.handle(@slideshow.url)
      slides = backend.all_slides_of(@slideshow.url, @slideshow.public_url, @video.duration)

      for slide, idx in slides
        slide.evenness = if (idx % 2) is 0 then "even" else "odd"

      chapter =
        duration: @video.duration
        video:
          url: @video.url
          thumb: @video.thumb
        slides: slides

      presentation =
        title: @title,
        chapters: [ chapter ],
        published: false

      presentation = new Presentation(presentation)
      router.navigate presentation.get("id")

    events:
      "change input[name=video_url]": "onchange_video"
      "change input[name=slide_url]": "onchange_slide"
      "change input[name=title]": "onchange_title"
      "click button": "onclick_start"

  class NavigationView extends Backbone.View

    el: $(".navbar > .navbar-inner > .container > .nav-collapse > .nav:first")

    reset: (highlight_idx) ->
      $("li:gt(1)", @$el).remove()
      $("li", @$el).removeClass "active"
      $("li", @$el).eq(highlight_idx).addClass "active" if highlight_idx?

    presentation_menu_entry: (title, published) ->
      $li = $("li", @$el)
      if $li.length < 3
        $li.removeClass "active"
        dust.render "_presentation_menu_entry", { title: title, published: published }, (err, out) =>
          return alert(err) if err?

          @$el.append(out)
          $helper.notify_save_text().hide()
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

    save: () ->
      app.save()

    events:
      "click a[href=#mypres]": "mypres"
      "click a[href=#make]": "make"
      "click button.save": "save"

  class AppView extends Backbone.View

    el: $ "body > .container"

    initialize: () ->
      @navigationView = new NavigationView()

      @presentationThumbList = new PresentationThumbList()

      @presentationThumbList.on "reset", @reset, @

    reset: (models) ->
      if models.length > 0
        view = new PresentationThumbListView model: models
        @$el.html view.el
        view.render()
      else
        dust.render "_no_talks_here", {}, (err, out) =>
          return alert(err) if err?

          @$el.html out
      loader_hide()

    mypres: () ->
      @presentationThumbList.fetch()
      @navigationView.reset(0)

    make: () ->
      @navigationView.reset(1)
      view = new PresentationNewView()
      @$el.html view.el
      view.render()

    edit: (model) ->
      @view = new PresentationEditView model: model
      @$el.html @view.el
      @view.render()

      prsntz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
        $helper.slides().movingBoxes(new_slide_index + 1)

      prsntz.on "timechange", (current_time) ->
        $helper.current_time().text(utils.my_parse_float(current_time))

      show_pause = () -> $helper.play_pause_btn().addClass("pause").removeClass("play")
      show_play = () -> $helper.play_pause_btn().removeClass("pause").addClass("play")
      prsntz.on "play", show_pause
      prsntz.on "pause", show_play
      prsntz.on "finish", show_play

      model.unbind "change", @edit

    save: () ->
      @view.save()

  app = new AppView()

  class AppRouter extends Backbone.Router

    routes:
      "": "go_mypres"
      "mypres": "mypres"
      "make": "make"
      ":presentation": "presentation"

    go_mypres: () ->
      @navigate "mypres", trigger: true

    mypres: () ->
      loader_show()
      app.mypres()

    make: () ->
      app.make()

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
  