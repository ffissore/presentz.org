class Dummy

  handle: (url) -> true

  fetch_info: (url, callback) ->
    if utils.is_url_valid url
      callback undefined, url: url, duration: 0
    else
      callback(new Error("invalid"))

@video_backends.Dummy = Dummy