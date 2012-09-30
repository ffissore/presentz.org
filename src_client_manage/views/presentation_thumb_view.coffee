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

class PresentationThumbView extends Backbone.View

  tagName: "li"

  className: "span3"

  initialize: () ->
    _.bindAll(@)

    @model.bind "change", @render

  render: () ->
    if @model.get("published")
      published_css_class = ""
      published_label = "Hide"
    else
      published_css_class = " btn-info"
      published_label = "Publish"

    ctx =
      thumb: @model.get("chapters.0.video.thumb")
      title: utils.cut_string_at(@model.get("title"), 30)
      published_css_class: published_css_class
      published_label: published_label
      
    dust.render "_presentation_thumb", ctx, (err, out) =>
      return views.alert(err) if err?

      @$el.html out
    @

  toogle_published: () ->
    @model.set("published", !@model.get "published")
    @model.save()
    false

  edit: () ->
    @trigger("edit", @model.get("id"))
    #router.navigate @model.get("id"), trigger: true
    false

  events:
    "click a.publish": "toogle_published"
    "click a.edit": "edit"

@views.PresentationThumbView = PresentationThumbView