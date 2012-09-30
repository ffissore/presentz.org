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

class Youtube

  constructor: (@presentzYoutube) ->

  handle: (url) ->
    @presentzYoutube.handle url: url

  id_from: (url) ->
    @presentzYoutube.videoId url: url

  query: (url, callback) ->
    id = @id_from(url)
    return callback("invalid url") if id is ""
    $.jsonp
      url: "https://gdata.youtube.com/feeds/api/videos/#{id}?v=2&alt=json"
      success: (response) ->
        callback(undefined, response)
      error: (options, status) ->
        callback(status)

  fetch_info: (url, callback) ->
    @query url, (err, response) =>
      return callback(err) if err?
      thumb = _.find(response.entry.media$group.media$thumbnail, (elem) -> elem.yt$name is "mqdefault")
      duration = parseInt(response.entry.media$group.yt$duration.seconds)
      url = "http://www.youtube.com/watch?v=#{@id_from(url)}"
      callback undefined, url: url, thumb: thumb.url, duration: duration

@video_backends.Youtube = Youtube
