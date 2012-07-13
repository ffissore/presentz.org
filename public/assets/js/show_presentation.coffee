Controls =

  init: () ->
    Controls.resize()

    $agenda_chapters = $("#controls .chapter")
    totalChapters = $agenda_chapters.length
    $agenda_chapters.each () ->
      $instance = $(this)

      $instance.unbind "mouseenter"

      $instance.bind "mouseenter", () ->
        selectedChapterWidth = $("#controls").width() + 1 - (totalChapters * 2)

        $agenda_chapters.not($instance).css "width", "2px"

        $instance.css("width", "#{selectedChapterWidth}px")
        $instance.find(".info").stop(true, true).delay(200).fadeIn(500)

      $instance.unbind "mouseleave"

      $instance.bind "mouseleave", () ->
        Controls.restoreOriginalWidth()

    $chapters = $("#controls .chapter, #chapters ol li")
    $chapters.unbind "click"
    $chapters.bind "click", (e) ->
      $this = $(e.target)
      if $this.hasClass("comments") or $this.parent(".comments").length > 0
        show('#comments')
      else
        if !$this.is("a")
          #this is NOT a typo
          $this = $(".info .title a", this)
        prsntz.changeChapter(parseInt($this.attr("chapter_index")), parseInt($this.attr("slide_index")), true)

  restoreOriginalWidth: () ->
    $("#controls .chapter").each () ->
      $(this).find(".info").stop(true, true).hide()
    Controls.resize()

  resize: () ->
    container_width = $("#controls").width()
    min_pixel_width = 2
    min_pixel_width_as_percentage = 100 * min_pixel_width / container_width
    $chapters = $("#controls .chapter")
    stolen_percentage = 0
    long_chapters_percentage = 0
    percentages = []

    #gather percentages and fix them if too low, accumulating stolen_percentage
    for chapter in $chapters
      $chapter = $(chapter)
      percentage = parseFloat($chapter.attr("percentage"))
      if percentage < min_pixel_width_as_percentage
        stolen_percentage += (min_pixel_width_as_percentage - percentage)
        percentage = min_pixel_width_as_percentage
      else
        long_chapters_percentage += percentage
      percentages.push(percentage)

    #resize chapters considering stolen_percentage and fix small chapters
    long_chapter_removed = false
    rounds = 0
    fix_as_many_small_chapters_as_possibile = () ->
      long_chapter_removed = false
      percentage_to_remove_from_long_chapters = 100 * stolen_percentage / long_chapters_percentage
      for percentage in percentages
        if percentage > min_pixel_width_as_percentage
          new_percentage = percentage - (percentage / 100 * percentage_to_remove_from_long_chapters)
          if new_percentage < min_pixel_width_as_percentage
            min_pixel_width_as_percentage = percentage
            long_chapter_removed = true
            long_chapters_percentage -= percentage
      rounds++
    fix_as_many_small_chapters_as_possibile()
    fix_as_many_small_chapters_as_possibile() while long_chapter_removed and rounds < 6

    #now percentages should be correct, lets rewrite the original ones
    percentage_to_remove_from_long_chapters = 100 * stolen_percentage / long_chapters_percentage
    for idx in [0...percentages.length]
      percentage = percentages[idx]
      if percentage > min_pixel_width_as_percentage
        percentage -= (percentage / 100 * percentage_to_remove_from_long_chapters)
        percentages[idx] = percentage

    #percentages to pixels
    sum_of_pixels = 0
    pixel_widths = []
    for percentage in percentages
      chapter_pixels = Math.floor(container_width / 100 * percentage)
      sum_of_pixels += chapter_pixels
      pixel_widths.push(chapter_pixels)

    #some pixel may still be missing, lets spread them
    while (container_width - sum_of_pixels) > 0
      for idx in [0...pixel_widths.length] when (container_width - sum_of_pixels) > 0
        pixel_widths[idx] = pixel_widths[idx] + 1
        sum_of_pixels += 1

    #now give each div its width in pixel
    for idx in [0...pixel_widths.length]
      $($chapters[idx]).css("width", "#{pixel_widths[idx]}px")

prsntz = new Presentz("#player_video", "460x420", "#slideshow_player", "460x420")

init_presentz = (presentation) ->
  oneBasedAbsoluteSlideIndex= (presentation, chapter_index, slide_index) ->
    absoluteSlideIndex = 0
    if chapter_index > 0
      for idx in [0...chapter_index]
        absoluteSlideIndex += presentation.chapters[idx].slides.length

    absoluteSlideIndex + slide_index + 1

  prsntz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
    fromSlide = oneBasedAbsoluteSlideIndex presentation, previous_chapter_index, previous_slide_index
    $from = $("#controls .chapter:nth-child(#{fromSlide}), #chapters ol li:nth-child(#{fromSlide}) a")
    $from.removeClass "selected"
    $from.addClass "past"

    toSlide = oneBasedAbsoluteSlideIndex presentation, new_chapter_index, new_slide_index
    $to = $("#controls .chapter:nth-child(#{toSlide}), #chapters ol li:nth-child(#{toSlide}) a")
    $to.removeClass "past"
    $to.addClass "selected"
    return

  #  prsntz.on "videochange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
  #    console.log "nothing"

  prsntz.init presentation
  prsntz.changeChapter 0, 0, false

openPopupTo = (width, height, url) ->
  left = (screen.width - width) / 2
  left = 0 if left < 0

  top = (screen.height - height) / 2
  top = 0 if top < 0

  window.open url, "share", "height=#{height},location=no,menubar=no,width=#{width},top=#{top},left=#{left}"
  return

fbShare = () ->
  openPopupTo 640, 350, "https://www.facebook.com/sharer.php?u=#{encodeURIComponent(document.location)}&t=#{encodeURIComponent(document.title)}"
  return

twitterShare = () ->
  openPopupTo 640, 300, "https://twitter.com/intent/tweet?text=#{encodeURIComponent("#{document.title} #{document.location} via @presentzorg")}"
  return

plusShare = () ->
  openPopupTo 640, 350, "https://plus.google.com/share?url=#{encodeURIComponent(document.location)}"
  return

hide = (to_hide_selector) ->
  $(to_hide_selector).css "display", "none"
  true

show = (to_show_selector) ->
  hide "#player .box8, #player .box8 #comment_form"
  $(to_show_selector).css "display", ""
  true

window.init_presentz = init_presentz
window.fbShare = fbShare
window.twitterShare = twitterShare
window.plusShare = plusShare
window.hide = hide
window.show = show

$().ready () ->
  Controls.init()

  $window = $(window)
  $window.unbind "resize"
  $window.bind "resize", () ->
    Controls.resize() if $("#controls").length > 0

  $("#comment_form form").submit (e) ->
    console.log e
    false
  return