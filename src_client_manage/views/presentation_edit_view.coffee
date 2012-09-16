$SLIDES = () -> $("div.slides")
$SLIDE_CONTAINERS = () -> $("div.row-fluid[slide_index]")
$SLIDE_THUMB = ($elem) -> $("div.slide_thumb", $elem)
$FORM_ROW_OF = ($elem) -> $elem.parentsUntil("div.control-group").parent()
$VIDEO_THUMB_OF = (chapter_index) -> $("img[chapter_index=#{chapter_index}]")
$CHAPTER_OF = ($elem) -> $elem.parentsUntil("span.chapter").last().parent()
$CHAPTER = (chapter_index) -> $("#chapter#{chapter_index}")
$SLIDE = (chapter_index, slide_index) -> $("span[chapter_index=#{chapter_index}] div[slide_index=#{slide_index}]")
$SLIDES_OF_CHAPTER = (chapter_index) -> $("span[chapter_index=#{chapter_index}] div[slide_index]")
$CURRENT_TIME = () -> $("span[name=current_time]")
$CHAPTER_INDEX_OF = ($elem) -> $CHAPTER_OF($elem).attr("chapter_index")
$MODEL_SELECTOR_OF_SLIDE = ($elem) ->
  chapter_index = $CHAPTER_INDEX_OF($elem)
  slide_index = $elem.attr("slide_index")
  "chapters.#{chapter_index}.slides.#{slide_index}"

change_simple_field = (self, fieldname, event) ->
  $elem = $(event.target)
  value = $.trim($elem.val())
  if value is ""
    self.model.unset fieldname
  else
    self.model.set fieldname, $elem.val()
  false

rebuild_slide_indexes = ($slides) ->
  $slides.each (slide_index, elem) ->
    $elem = $(elem)
    $elem.attr("slide_index", slide_index)
    $("[slide_index]", $elem).each (idx, subelem) ->
      $(subelem).attr("slide_index", slide_index)
    $("[placeholder]", $elem).each (idx, subelem) ->
      $(subelem).attr("placeholder", "Slide #{slide_index + 1}")

class PresentationEditView extends Backbone.View

  tagName: "div"

  initialize: (_ignore, @prsntz, @video_backends, @slide_backends) ->
    _.bindAll(@)

    @model.bind "all", (event) =>
      if @model.loaded and _.str.startsWith(event, "change")
        @trigger("enable_save_button")

    @model.bind "sync", () =>
      @trigger("disable_save_button")

    @model.bind "error", (model, error) ->
      if _.isString(error)
        views.alert(error)
      else if error.status?
        views.alert("Error: (#{error.status}): #{error.responseText}")
      else if error.message?
        views.alert("Error: #{error.message}")

  init_presentz: (presentation, first) ->
    @prsntz.init(presentation)
    @prsntz.changeChapter(0, 0, false)
    return unless first? and first

    $video = $("#video")
    $video_parent = $video.parent()
    $video.width $video_parent.width()
    $video.height $video_parent.height()

    @prsntz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
      $SLIDES().movingBoxes(new_slide_index + 1)

    @prsntz.on "timechange", (current_time) ->
      $CURRENT_TIME().text(utils.my_parse_float(current_time))

    show_pause = () -> $("a.play_pause_btn").addClass("pause").removeClass("play")
    show_play = () -> $("a.play_pause_btn").removeClass("pause").addClass("play")
    @prsntz.on "play", show_pause
    @prsntz.on "pause", show_play
    @prsntz.on "finish", show_play

  render: () ->
    views.scroll_top()
    ctx = @model.attributes
    ctx.onebased = dustjs_helpers.onebased

    slides = []
    for chapter in @model.attributes.chapters
      for slide, idx in chapter.slides
        slides.push slide

    load_slides_info = (slides, callback) =>
      slide = slides.pop()
      backend = _.find @slide_backends, (backend) -> backend.handle(slide.url)
      slide._thumb_type = backend.thumb_type_of slide.url
      backend.slide_info slide, (err, slide, slide_info) =>
        return views.alert(err) if err?

        slide.public_url = slide_info.public_url
        slide.number = slide_info.number if slide_info.number?
        slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?

        if slides.length > 0
          load_slides_info(slides, callback)
        else
          callback()

    load_slides_info slides, () =>
      dust.render "_presentation", ctx, (err, out) =>
        return views.alert(err) if err?

        views.loader_hide()

        @$el.html(out)

        when_rendered = () =>
          @trigger("presentation_title", @model.get("title"), @model.get("published"))

          $("input[name=time]").datepicker(dateFormat: "yymmdd")

          $SLIDES().movingBoxes
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
              for $elem in $SLIDE_CONTAINERS()
                $slide_thumb = $SLIDE_THUMB($elem)
                $slide_thumb.empty()

              $slide_thumb = $SLIDE_THUMB(curPanel.$curPanel)
              dust.render "_#{$slide_thumb.attr("thumb_type")}_slide_thumb", { slide_thumb: $slide_thumb.attr("src")}, (err, out) ->
                return views.alert(err) if err?

                $slide_thumb.html out

          @init_presentz(@model.attributes, true)
          views.disable_forms()

        #TODO: WTF? is .html async?
        setTimeout when_rendered, 100
    @

  onchange_title: (event) ->
    change_simple_field(@, "title", event)
    @trigger("presentation_title", @model.get("title"), @model.get("published"))
    false

  onchange_video_url: (event) ->
    $elem = $(event.target)
    url = $elem.val()
    backend = _.find @video_backends, (backend) -> backend.handle(url)
    backend.fetch_info url, (err, info) =>
      $form_row = $FORM_ROW_OF($elem)
      $video_error_msg_container = $(".video_alerts")
      if err?
        $form_row.addClass("error")
        $video_error_msg_container.addClass("alert alert-warning").html("Invalid URL")
      else
        $form_row.removeClass "error"
        $video_error_msg_container.removeClass("alert alert-warning").empty()

        chapter_index = $elem.attr("chapter_index")
        @model.set("chapters.#{chapter_index}.video.url", info.url)
        @model.set("chapters.#{chapter_index}.duration", info.duration)
        $("input[name=video_duration][chapter_index=#{chapter_index}]").val(info.duration)
        @init_presentz @model.attributes
        if info.thumb?
          dust.render "_reset_thumb", { chapter_index: chapter_index }, (err, out) ->
            return views.alert(err) if err?

            $video_error_msg_container.html(out)
    false

  reset_video_thumb: (event) ->
    $elem = $(event.target)
    chapter_index = parseInt($elem.attr("chapter_index"))
    video_url = @model.get("chapters.#{chapter_index}.video.url")

    backend = _.find @video_backends, (backend) -> backend.handle(video_url)
    backend.fetch_info video_url, (err, info) =>
      return views.alert(err) if err?

      @model.set("chapters.#{chapter_index}.video.thumb", info.thumb)

      $thumb_input = $("#chapter#{chapter_index} input[name=video_thumb]")
      $thumb_input.val(info.thumb)
      $thumb_input.change()

      $VIDEO_THUMB_OF(chapter_index).attr("src", info.thumb)

      $elem.remove()
    false

  onchange_video_duration: (event) ->
    $elem = $(event.target)
    chapter_index = $elem.attr("chapter_index")
    @model.set("chapters.#{chapter_index}.duration", parseInt($elem.val()))
    false

  onchange_video_thumb_url: (event) ->
    $elem = $(event.target)
    thumb_url = $elem.val()
    $video_error_msg_container = $(".video_alerts")
    $form_row = $FORM_ROW_OF($elem)

    if utils.is_url_valid(thumb_url)
      $form_row.removeClass "error"
      $video_error_msg_container.removeClass("alert alert-warning").empty()
      chapter_index = $elem.attr("chapter_index")
      @model.set("chapters.#{chapter_index}.video.thumb", thumb_url)
      $VIDEO_THUMB_OF(chapter_index).attr("src", thumb_url)
    else
      $form_row.addClass("error")
      $video_error_msg_container.addClass("alert alert-warning").html("Invalid URL")
    false

  onchange_slide_title: (event) ->
    $elem = $(event.target)
    selector = $MODEL_SELECTOR_OF_SLIDE($elem)

    @model.set("#{selector}.title", $elem.val())

  onchange_slide_number: (event) ->
    $elem = $(event.target)
    selector = $MODEL_SELECTOR_OF_SLIDE($elem)

    slide = @model.get(selector)
    backend = _.find @slide_backends, (backend) -> backend.handle(slide.url)

    new_url = backend.change_slide_number(slide.url, $elem.val())
    @model.set("#{selector}.url", new_url)

    backend.slide_info slide, (err, slide, slide_info) =>
      if err?
        views.alert err, () ->
          $elem.focus()
        return
      slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?

      $slide_thumb = $SLIDE_THUMB($SLIDE($CHAPTER_INDEX_OF($elem), $elem.attr("slide_index")))
      $slide_thumb.attr("src", slide.slide_thumb)
      dust.render "_#{$slide_thumb.attr("thumb_type")}_slide_thumb", { slide_thumb: $slide_thumb.attr("src")}, (err, out) ->
        return views.alert(err) if err?

        $slide_thumb.html out

  onchange_slide_time: (event) ->
    $elem = $(event.target)
    selector = $MODEL_SELECTOR_OF_SLIDE($elem)

    slide = @model.get(selector)
    backend = _.find @slide_backends, (backend) -> backend.handle(slide.url)

    @model.set("#{selector}.time", Math.round($elem.val()))

    chapter_index = $CHAPTER_INDEX_OF($elem)
    slides = @model.get("chapters.#{chapter_index}.slides")
    source_index = slides.indexOf(slide)
    slides = _.sortBy slides, (slide) -> slide.time
    dest_index = slides.indexOf(slide)
    return if source_index is dest_index

    @model.set("chapters.#{chapter_index}.slides", slides)

    $source_element = $SLIDE(chapter_index, source_index)
    $dest_element = $SLIDE(chapter_index, dest_index)
    if dest_index < source_index
      $source_element.insertBefore($dest_element)
    else
      $source_element.insertAfter($dest_element)

    $SLIDES().movingBoxes()
    $SLIDES().movingBoxes(dest_index + 1)
    rebuild_slide_indexes($SLIDES_OF_CHAPTER(chapter_index))

  onchange_slide_public_url: (event) ->
    $elem = $(event.target)
    public_url = $elem.val()
    return if !utils.is_url_valid(public_url)

    selector = $MODEL_SELECTOR_OF_SLIDE($elem)

    @model.set("#{selector}.public_url", public_url)

    backend = _.find @slide_backends, (backend) -> backend.handle(public_url)
    slide = @model.get(selector)

    backend.url_from_public_url slide, (err, new_url) =>
      return views.alert(err) if err?

      @model.set("#{selector}.url", new_url)

      backend.slide_info slide, (err, slide, slide_info) =>
        return views.alert(err) if err?

        slide.slide_thumb = slide_info.slide_thumb if slide_info.slide_thumb?
        $slide_thumb = $SLIDE_THUMB($SLIDE($CHAPTER_INDEX_OF($elem), $elem.attr("slide_index")))
        $slide_thumb.attr("src", slide.slide_thumb)
        $slide_thumb.attr("thumb_type", backend.thumb_type_of(slide.url))
        dust.render "_#{$slide_thumb.attr("thumb_type")}_slide_thumb", { slide_thumb: $slide_thumb.attr("src")}, (err, out) ->
          return views.alert(err) if err?

          $slide_thumb.html out

  save: () ->
    @model.save()
    @model.get("id")

  onclick_playpause: (event) ->
    $btn = $(event.target)
    if @prsntz.isPaused()
      @prsntz.play()
    else
      @prsntz.pause()
    false

  ###
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
      backend = _.find @slide_backends, (backend) -> backend.handle(first_slide_url)

      dust.render "_slide_times_preview", { value_type: backend.import_file_value_column, data: @data }, (err, out) ->
        return alert(err) if err?
        $(".modal-body", $helper.advanced_user_data_preview()).html(out)
        views.disable_forms()

    reader.readAsText(file)

  onclick_confirm_data_import: () ->
    slides = @model.get("chapters.0.slides")
    check_import_data = (callback) =>
      checked = 0
      for slide, idx in slides when idx < @data.length
        data_for_slide = @data[idx]
        backend = _.find @slide_backends, (backend) -> backend.handle(slide.url)
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
        backend = _.find @slide_backends, (backend) -> backend.handle(slide.url)
        backend.set_slide_value_from_import(slide, data_for_slide.value)

      @model.set("chapters.0.slides", slides)
      $helper.advanced_user_data_preview().modal("hide")
      @render()
  ###

  onclick_slide_delete: (event) ->
    $elem = $(event.target)
    $slide_container = $elem.parentsUntil("div.row-fluid[slide_index]").last().parent()
    slide_index = $slide_container.attr("slide_index")
    chapter_index = $CHAPTER_OF($elem).attr("chapter_index")

    $btn_confirm = $("#slide_delete_confirm .btn-success")
    $btn_confirm.attr("chapter_index", chapter_index)
    $btn_confirm.attr("slide_index", slide_index)
    $("#slide_delete_confirm").modal("show")

    false

  onclick_slide_delete_confirmed: (event) ->
    $elem = $(event.target)
    $("#slide_delete_confirm").modal("hide")

    chapter_index = parseInt($elem.attr("chapter_index"))
    slide_index = parseInt($elem.attr("slide_index"))

    slides = @model.get("chapters.#{chapter_index}.slides")
    slide_to_delete = slides.splice(slide_index, 1)[0]

    @model.set("chapters.#{chapter_index}.slides", slides)
    @model.slides_to_delete.push(slide_to_delete)

    if slide_index is slides.length
      new_slide_index = slides.length - 1
    else
      new_slide_index = slide_index

    $SLIDES().movingBoxes(new_slide_index + 1)
    $SLIDE(chapter_index, slide_index).remove()
    $SLIDES().movingBoxes()

    rebuild_slide_indexes($SLIDES_OF_CHAPTER(chapter_index))

    false

  onclick_slide_delete_aborted: (event) ->
    $("#slide_delete_confirm").modal("hide")
    false

  onclick_set_time: (event) ->
    @prsntz.pause()

    slide_index = $SLIDES().getMovingBoxes().curPanel - 1
    slide_time = utils.my_parse_float($CURRENT_TIME().text())
    @model.set("chapters.0.slides.#{slide_index}.time", slide_time)
    $("input.slide_time", $SLIDE(0, slide_index)).val(slide_time)
    $slide_time_elem = $("input.slide_time", $SLIDES().getMovingBoxes().$curPanel)
    @onchange_slide_time(target: $slide_time_elem)
    false

  onclick_add_slide: () ->
    @prsntz.pause()
    
    find_next_slide_idx = (slides, time) ->
      for slide, idx in slides
        return idx if slide.time > time

      return slides.length

    slides = @model.get("chapters.0.slides")
    new_time = utils.my_parse_float($CURRENT_TIME().text())
    new_index = find_next_slide_idx(slides, new_time)

    slide_template = @model.get("chapters.0.slides.#{$SLIDES().getMovingBoxes().curPanel - 1}")
    backend = _.find @slide_backends, (backend) -> backend.handle(slide_template.url)
    new_slide = backend.make_new_from(slide_template)

    new_slide._index = new_index
    new_slide._onebased_index = new_slide._index + 1
    new_slide.time = new_time

    slides = @model.get("chapters.0.slides")
    slides.splice(new_index, 0, new_slide)
    @model.set("chapters.0.slides", slides)

    dust.render "_slide", new_slide, (err, out) =>
      if new_index is slides.length
        $SLIDES_OF_CHAPTER(0).last().after(out)
      else if new_index is 0
        $SLIDES_OF_CHAPTER(0).first().before(out)
      else
        $SLIDE(0, new_index - 1).after(out)

      $SLIDES().movingBoxes()
      $SLIDES().movingBoxes(new_index + 1)
      rebuild_slide_indexes($SLIDES_OF_CHAPTER(0))
      views.disable_forms()
    false

  onchange_speaker: (event) ->
    change_simple_field(@, "speaker", event)

  onchange_time: (event) ->
    change_simple_field(@, "time", event)

  events:
    "click a.play_pause_btn": "onclick_playpause"
    "click a.set_time_btn": "onclick_set_time"
    "click a.add_slide_btn": "onclick_add_slide"
    #"click a.hei_advanced": "onclick_advanced_user"
    #"click #advanced_user_data_preview button.btn-danger": "onclick_advanced_user"
    #"click #advanced_user_data_preview button.btn-success": "onclick_confirm_data_import"
    #"change input[type=file]": "onchange_slide_times_file"

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

    "click a.slide_delete": "onclick_slide_delete"
    "click #slide_delete_confirm button.btn-danger": "onclick_slide_delete_aborted"
    "click #slide_delete_confirm button.btn-success": "onclick_slide_delete_confirmed"

@views.PresentationEditView = PresentationEditView
