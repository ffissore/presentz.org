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

class None

  constructor: () ->

  handle: (url) ->
    return !url?

  is_dummy: () -> true

  thumb_type_of: (url) ->
    "none"

  slide_info: (slide, callback) ->
    callback undefined, slide, slide

  first_slide: (slideshow) ->
    slide_backends.make_new_slide(null, 0)

  slideshow_info: (url, callback) ->
    slide = { url: url }
    callback undefined, slide, slide

  url_from_public_url: (slide, public_url, callback) ->
    callback undefined, public_url

  set_slide_value_from_import: () ->

  check_slide_value_from_import: (slide, slide_number, callback) ->
    callback()

  make_new_from: (slide) ->
    new_slide = slide_backends.make_new_slide(null, slide.time)
    new_slide._thumb_type = "none"
    new_slide._plugin_id = slide._plugin_id if slide._plugin_id?
    new_slide

@slide_backends.None = None