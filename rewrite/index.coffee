_ = require "underscore"
_s = require "underscore.string"

third_level_domain_regex = /([\w]+)\.[\w]+\..+/

rewrite_on_match = (req) ->
  match = req.headers.host.match third_level_domain_regex
  if match and req.path.indexOf(match[1]) == -1
    req.url_original = req.url
    req.url = "/#{match[1]}#{req.url}"

rewriter = (statics) ->
  if typeof statics == "string"
    return (req, res, next) ->
      url_parts = req.url.split("/")
      rewrite_on_match req if url_parts[1] isnt statics
      next()

  return (req, res, next) ->
    url_parts = req.url.split("/")
    rewrite_on_match req if not _.find(statics, (elem) -> elem == url_parts[1])
    next()

module.exports.rewriter = rewriter
