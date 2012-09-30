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

express = require "express"
redirect_routes = require "./routes_redirect"

subdomain = express()

config = require "./config.#{subdomain.settings.env}"

subdomain.configure ->
  subdomain.use express.logger()
  subdomain.use express.methodOverride()
  subdomain.use redirect_routes.redirect_to_catalog_if_subdomain()
  subdomain.use redirect_routes.redirect_to "http://presentz.org/"
  subdomain.use express.errorHandler()

subdomain.listen config.subdomain_port
console.log "Express server listening on port #{config.subdomain_port} in #{subdomain.settings.env} mode"
