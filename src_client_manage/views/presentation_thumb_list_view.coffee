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

class PresentationThumbListView extends Backbone.View

  tagName: "ul"

  className: "thumbnails"

  initialize: () ->
    _.bindAll(@)

  render: () ->
    views.scroll_top()
    
    @model.each (model) =>
      view = new views.PresentationThumbView(model: model)
      view.render().bind("edit", @edit)
      @$el.append(view.el)
    @
  
  edit: (id) ->
    @trigger("edit", id)
    false

@views.PresentationThumbListView = PresentationThumbListView