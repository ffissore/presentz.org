"use strict"

redirect_to = (url) ->
  return (req, res, next) ->
    res.redirect 302, url

back_to_referer = (config) ->
  return (req, res, next) ->
    if req.headers? and req.headers.referer?
      res.redirect 302, req.headers.referer
    else
      res.redirect 302, config.hostname

redirect_to_catalog_if_subdomain = () ->
  third_level_domain_regex = /([\w]+)\.[\w]+\..+/
  return (req, res, next) ->
    proxy = req.headers["x-forwarded-host"]
    if proxy?
      match = proxy.match third_level_domain_regex
      if match?
        res.redirect 302, "http://#{proxy.replace("#{match[1]}.", "")}/#{match[1]}#{req.url}"

exports.redirect_to = redirect_to
exports.back_to_referer = back_to_referer
exports.redirect_to_catalog_if_subdomain = redirect_to_catalog_if_subdomain