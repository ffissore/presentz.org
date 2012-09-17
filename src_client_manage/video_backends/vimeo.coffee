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
