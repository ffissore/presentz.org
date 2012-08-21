class YouTube

  handle: (url) ->
    url.toLowerCase().indexOf("youtu.be") != -1

  id_from = (url) ->
    url.substr url.lastIndexOf("/") + 1

  query = (url, callback) ->
    return callback("invalid url") if id_from(url) is ""
    $.jsonp
      url: "https://gdata.youtube.com/feeds/api/videos/#{id_from(url)}?v=2&alt=json"
      success: (response) ->
        callback(undefined, response)
      error: (options, status) ->
        callback(status)

  is_valid: (url, callback) ->
    query url, callback

  fetch_thumb: (url, callback) ->
    query url, (err, response) ->
      return callback(err) if err?
      thumb = _.find(response.entry.media$group.media$thumbnail, (elem) -> elem.yt$name is "mqdefault")
      callback(undefined, thumb.url)

class Vimeo

  handle: (url) ->
    url.toLowerCase().indexOf("vimeo.com") != -1

  id_from = (url) ->
    url.substr url.lastIndexOf("/") + 1

  query = (url, callback) ->
    return callback("invalid url") if id_from(url) is ""
    $.jsonp
      url: "http://vimeo.com/api/v2/video/#{id_from(url)}.json"
      success: (response, status) ->
        callback(undefined, response)
      error: (options, status) ->
        callback(status)

  is_valid: (url, callback) ->
    query url, callback

  fetch_thumb: (url, callback) ->
    query url, (err, videos) ->
      return callback(err) if err?
      callback(undefined, videos[0].thumbnail_medium)

@presentzorg.video_backends = {}
@presentzorg.video_backends.YouTube = YouTube
@presentzorg.video_backends.Vimeo = Vimeo