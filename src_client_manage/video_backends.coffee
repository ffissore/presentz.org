class Youtube

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

  fetch_info: (url, callback) ->
    query url, (err, response) ->
      return callback(err) if err?
      thumb = _.find(response.entry.media$group.media$thumbnail, (elem) -> elem.yt$name is "mqdefault")
      duration = parseInt(response.entry.media$group.yt$duration.seconds)
      callback undefined, url: url, thumb: thumb.url, duration: duration

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

  fetch_info: (url, callback) ->
    query url, (err, videos) ->
      return callback(err) if err?
      callback undefined, url: videos[0].url, thumb: videos[0].thumbnail_medium, duration: videos[0].duration

      
class DummyVideoBackend

  handle: (url) -> true

  fetch_info: (url, callback) ->
    if @presentzorg.is_url_valid url
      callback undefined, url: url, duration: -1
    else
      callback("invalid")

@presentzorg.video_backends = {}
@presentzorg.video_backends.Youtube = Youtube
@presentzorg.video_backends.Vimeo = Vimeo
@presentzorg.video_backends.DummyVideoBackend = DummyVideoBackend