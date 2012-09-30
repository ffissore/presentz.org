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

class Vimeo

  constructor: (@presentzVimeo) ->

  handle: (url) ->
    @presentzVimeo.handle url: url

  id_from: (url) ->
    @presentzVimeo.videoId url: url

  query: (url, callback) ->
    return callback("invalid url") if @id_from(url) is ""
    $.jsonp
      url: "http://vimeo.com/api/v2/video/#{@id_from(url)}.json"
      success: (response, status) ->
        callback(undefined, response)
      error: (options, status) ->
        callback(status)

  fetch_info: (url, callback) ->
    @query url, (err, videos) ->
      return callback(err) if err?
      video = videos[0]
      callback undefined, url: video.url, thumb: video.thumbnail_medium, duration: video.duration

@video_backends.Vimeo = Vimeo
