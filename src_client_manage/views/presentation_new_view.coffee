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

class PresentationNewView extends Backbone.View

  tagName: "div"

  @video: null
  @slideshow: null
  @title: null

  initialize: (@video_backends, @slide_backends) ->
    _.bindAll(@)

  render: () ->
    views.scroll_top()
    dust.render "_new", {}, (err, out) =>
      return views.alert(err) if err?
      views.loader_hide()
      @$el.html(out)
      views.disable_forms()
    @

  check_if_time_to_start: () ->
    $button = $("button", @$el)
    if @video? and @slideshow? and @title? and @title isnt ""
      $button.removeClass("disabled")
      $button.attr("disabled", false)
    else
      $button.addClass("disabled")
      $button.attr("disabled", true)

  onchange_video: (event) ->
    $elem = $(event.target)
    url = $elem.val()
    return if url is ""

    url = "http://#{url}" unless _.str.startsWith(url, "http")
    $thumb_container = $(".video_thumb", @$el)
    $thumb_container.empty()
    $thumb_container.html("Fetching info...")
    backend = _.find @video_backends, (backend) -> backend.handle(url)
    backend.fetch_info url, (err, info) =>
      $thumb_container.empty()
      @video = null

      if err?
        $thumb_container.html("<div class=\"alert alert-error\">This URL does not look good</div>")
        return

      feedback = "<p>Looks good!"
      if info.thumb?
        feedback = feedback.concat(" Here is the thumb.</p><img class=\"smallthumb\" src=\"#{info.thumb}\"/>")
      else
        feedback = feedback.concat(" At least the URL is well made. Hope that is a video file.</p>")
      $thumb_container.html(feedback)
      @video = info
      @check_if_time_to_start()

  onchange_slide: (event) ->
    $elem = $(event.target)
    url = $elem.val()
    return if url is ""

    $thumb_container = $(".slide_thumb", @$el)
    $thumb_container.empty()
    $thumb_container.html("Fetching info...")
    backend = _.find @slide_backends, (backend) -> backend.handle(url)
    backend.slideshow_info url, (err, slideshow_info) =>
      $thumb_container.empty()
      @slideshow = null

      if err?
        $thumb_container.html("<div class=\"alert alert-error\">This URL does not look good (#{err})</div>")
        return

      $override_slide_plugin = $(".override_slide_plugin", @$el)
      if backend.is_dummy()
        $override_slide_plugin.removeClass("hidden")
      else
        $override_slide_plugin.addClass("hidden")
  
      $thumb_container.html("<p>Looks good! Here is the first slide.</p>")
      @slideshow = slideshow_info
      @check_if_time_to_start()
      thumb_type = backend.thumb_type_of(slideshow_info.slide_thumb)
      dust.render "_#{thumb_type}_slide_thumb", slideshow_info, (err, out) ->
        return views.alert(err) if err?
        $thumb_container.append(out)
        views.disable_forms()

      $title = $("input[name=title]")
      if slideshow_info.title? and $title.val() is ""
        $title.val(slideshow_info.title)
        $title.change()

  onchange_title: (event) ->
    $elem = $(event.target)
    @title = $elem.val()
    @check_if_time_to_start()

  onclick_start: () ->
    backend = _.find @slide_backends, (backend) => backend.handle(@slideshow.url)
    slides = [ backend.first_slide(@slideshow) ]

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

    presentation = new models.Presentation(presentation)
    @trigger("new", presentation)

  events:
    "change input[name=video_url]": "onchange_video"
    "change input[name=slide_url]": "onchange_slide"
    "change input[name=title]": "onchange_title"
    "click button": "onclick_start"

@views.PresentationNewView = PresentationNewView