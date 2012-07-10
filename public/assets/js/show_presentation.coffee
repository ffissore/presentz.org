prsntz = new Presentz("#player_video", "460x420", "#slideshow_player", "460x420")

init_presentz = (presentation) ->
  oneBasedAbsoluteSlideIndex = (presentation, chapter_index, slide_index) ->
    absoluteSlideIndex = 0
    if chapter_index > 0
      for idx in [0...chapter_index]
        absoluteSlideIndex += presentation.chapters[idx].slides.length

    absoluteSlideIndex + slide_index + 1

  prsntz.on "slidechange", (previous_chapter_index, previous_slide_index, new_chapter_index, new_slide_index) ->
    fromSlide = oneBasedAbsoluteSlideIndex presentation, previous_chapter_index, previous_slide_index
    $from = $("#controls .chapter:nth-child(#{fromSlide})")
    $from.removeClass "selected"
    $from.addClass "past"

    toSlide = oneBasedAbsoluteSlideIndex presentation, new_chapter_index, new_slide_index
    $to = $("#controls .chapter:nth-child(#{toSlide})")
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

fbShare = ->
  openPopupTo 640, 350, "https://www.facebook.com/sharer.php?u=#{encodeURIComponent(document.location)}&t=#{encodeURIComponent(document.title)}"
  return

twitterShare = ->
  openPopupTo 640, 300, "https://twitter.com/intent/tweet?text=#{encodeURIComponent("#{document.title} #{document.location} via @presentzorg")}"
  return

plusShare = ->
  openPopupTo 640, 350, "https://plus.google.com/share?url=#{encodeURIComponent(document.location)}"
  return

hide = (to_hide_selector) ->
  $(to_hide_selector).css "display", "none"
  true

show = (to_show_selector) ->
  hide "#player .box8, #player .box8 #comment_form"
  $(to_show_selector).css "display", ""
  true

window.prsntz = prsntz
window.init_presentz = init_presentz
window.fbShare = fbShare
window.twitterShare = twitterShare
window.plusShare = plusShare
window.hide = hide
window.show = show