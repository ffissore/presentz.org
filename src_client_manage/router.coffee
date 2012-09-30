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

class AppRouter extends Backbone.Router

  initialize: (@app_view) ->
    _.bindAll(@)
    
    @app_view.bind "edit_presentation", (id) =>
      @navigate(id, trigger: true)

    @app_view.bind "new_presentation", (id) =>
      @navigate(id)
    @app_view.bind "mypres", () =>
      @go_mypres()

  routes:
    "": "go_mypres"
    "mypres": "mypres"
    "make": "make"
    "hp": "hp"
    ":presentation": "presentation"

  go_mypres: () ->
    @navigate("mypres", trigger: true)

  mypres: () ->
    @app_view.mypres()

  make: () ->
    @app_view.make()

  hp: () ->
    window.location = "/"

  presentation: (id) ->
    @app_view.presentation(id)

@AppRouter = AppRouter