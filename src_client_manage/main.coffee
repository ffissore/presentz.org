###
Presentz.org - A website to publish presentations with video and slides synchronized.

Copyright (C) 2012 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

"use strict"

jQuery () ->
  ###
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
  ###

  prsntz = new Presentz("#video", "450x400", "#slide", "450x400")

  video_backends = [new window.video_backends.Youtube(prsntz.availableVideoPlugins.youtube), new window.video_backends.Vimeo(prsntz.availableVideoPlugins.vimeo), new window.video_backends.Dummy(prsntz.availableVideoPlugins.html5)]
  slide_backends = [new window.slide_backends.SlideShare(prsntz.availableSlidePlugins.slideshare), new window.slide_backends.Speakerdeck(prsntz.availableSlidePlugins.speakerdeck), new window.slide_backends.Dummy(prsntz.availableSlidePlugins.image)]

  app = new window.views.AppView(prsntz, video_backends, slide_backends)
  router = new window.AppRouter(app)

  window.views.alert().modal(show: false)
  window.views.confirm().modal(show: false)

  $("ul.nav a").click (event) ->
    return true unless app.dirty
    window.views.confirm "You have unsaved changes. Are you sure you want to proceed?", () ->
      window.location.hash = event.target.hash
    false

  Backbone.history.start pushState: false, root: "/m/"
  $.jsonp.setup callbackParameter: "callback"
  