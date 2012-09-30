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