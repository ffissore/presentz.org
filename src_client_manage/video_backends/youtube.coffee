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
