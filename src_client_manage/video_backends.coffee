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

class DummyVideoBackend

  handle: (url) -> true

  fetch_info: (url, callback) ->
    if utils.is_url_valid url
      callback undefined, url: url, duration: 0
    else
      callback(new Error("invalid"))

@presentzorg.video_backends = {}
@presentzorg.video_backends.Youtube = Youtube
@presentzorg.video_backends.Vimeo = Vimeo
@presentzorg.video_backends.DummyVideoBackend = DummyVideoBackend