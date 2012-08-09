redirect_to = (url) ->
  return (req, res, next) ->
    res.redirect 302, url

back_to_referer = (config) ->
  return (req, res, next) ->
    if req.headers? and req.headers.referer?
      redirect_to req.headers.referer
    else
      redirect_to config.hostname

redirect_to_catalog_if_subdomain = () ->
  third_level_domain_regex = /([\w]+)\.[\w]+\..+/
  return (req, res, next) ->
    proxy = req.headers["x-forwarded-host"]
    if proxy?
      match = proxy.match third_level_domain_regex
      if match?
        redirect_to "http://#{proxy.replace("#{match[1]}.", "")}/#{match[1]}#{req.url}"

exports.redirect_to = redirect_to
exports.back_to_referer = back_to_referer
exports.redirect_to_catalog_if_subdomain = redirect_to_catalog_if_subdomain