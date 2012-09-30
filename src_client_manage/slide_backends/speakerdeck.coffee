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

class Speakerdeck

  constructor: (@presentzSpeakerdeck) ->
    @public_url_data_id = {}
    @import_file_value_column = "Slide Index"

  handle: (url) ->
    @presentzSpeakerdeck.handle url: url

  thumb_type_of: (url) -> "img"

  to_data_id: (url) ->
    @presentzSpeakerdeck.slideId url: url

  to_slide_number: (url) ->
    parseInt(@presentzSpeakerdeck.slideNumber(url: url))

  to_thumb: (url) ->
    number = @to_slide_number(url)
    data_id = @to_data_id(url)
    "https://speakerd.s3.amazonaws.com/presentations/#{data_id}/thumb_slide_#{number - 1}.jpg"

  clean_url = (url) ->
    url = Uri(url)
    "#{url.protocol()}://#{url.host()}#{url.path()}"

  make_url = (data_id, slide_number) ->
    "https://speakerdeck.com/#{data_id}##{slide_number}"

  first_slide: (slideshow) ->
    slide_backends.make_new_slide(slideshow.url, 0, slideshow.public_url)

  slideshow_info: (public_url, callback) ->
    public_url = "https://#{public_url}" unless _.str.startsWith(public_url, "https://")
    public_url = clean_url(public_url)
    @url_from_public_url url: "#{public_url}#1", public_url, (err, new_url) =>
      return callback(err) if err?

      slide =
        url: new_url
        public_url: public_url
        number: @to_slide_number(new_url)
        slide_thumb: @to_thumb(new_url)
      callback undefined, slide

  slide_info: (slide, callback) ->
    callback undefined, slide,
      public_url: slide.public_url
      number: @to_slide_number(slide.url)
      slide_thumb: @to_thumb(slide.url)

  url_from_public_url: (slide, public_url, callback) ->
    slide_number = @to_slide_number slide.url

    if @public_url_data_id[public_url]?
      callback(undefined, make_url(@public_url_data_id[public_url], slide_number))
      return

    $.ajax
      type: "GET"
      url: "/m/api/speakerdeck/url_to_data_id"
      data:
        { url: public_url }
      success: (response) =>
        @public_url_data_id[public_url] = response.data_id
        callback(undefined, make_url(@public_url_data_id[public_url], slide_number))
      error: (jqXHR, textStatus, errorThrown) ->
        callback("Invalid url", public_url)

  make_new_from: (slide) ->
    data_id = @to_data_id(slide.url)
    if $("iframe.speakerdeck-iframe").length > 0
      slide_number = @presentzSpeakerdeck.currentSlide
    else
      slide_number = @to_slide_number(slide.url)

    slide_url = make_url(data_id, slide_number)
    new_slide = slide_backends.make_new_slide(slide_url, slide.time, slide.public_url)
    new_slide._thumb_type = "img"
    new_slide.number = slide_number
    new_slide.slide_thumb = @to_thumb(slide_url)
    new_slide

  change_slide_number: (old_url, slide_number) ->
    old_url.substring(0, old_url.lastIndexOf("#") + 1).concat(slide_number)

  check_slide_value_from_import: (slide, slide_number, callback) ->
    callback()

  set_slide_value_from_import: (slide, slide_number) ->
    slide.url = @change_slide_number(slide.url, slide_number)

@slide_backends.Speakerdeck = Speakerdeck
