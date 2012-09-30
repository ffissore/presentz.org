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

class AppView extends Backbone.View

  dirty: false

  el: $ "body > .container"

  initialize: (@prsntz, @video_backends, @slide_backends) ->
    _.bindAll(@)

    @navigation_view = new views.NavigationView()
    @navigation_view.bind "save", @save

    @presentation_thumb_list = new models.PresentationThumbList()
    @presentation_thumb_list.on "reset", @render_thumb_list, @

  render_thumb_list: (models) ->
    if models.length > 0
      view = new views.PresentationThumbListView model: models
      @$el.html view.el
      view.render()
      view.bind "edit", (id) =>
        @trigger("edit_presentation", id)

    else
      dust.render "_no_talks_here", {}, (err, out) =>
        return views.alert(err) if err?
        @$el.html out
        views.disable_forms()

    views.loader_hide()

  mypres: () ->
    @clear_dirty()
    views.loader_show()
    @presentation_thumb_list.fetch()
    @navigation_view.reset(0)

  make: () ->
    @clear_dirty()
    @navigation_view.reset(1)
    view = new views.PresentationNewView(@video_backends, @slide_backends)
    view.render()
    view.bind "new", (presentation) =>
      @edit(presentation, null, true)
      @trigger("new_presentation", presentation.get("id"))
    @$el.html view.el

  presentation: (id) ->
    @clear_dirty()
    views.loader_show()
    presentation = new models.Presentation({ id: id })
    presentation.bind "change", @edit
    presentation.bind "error", (model, error) =>
      error = JSON.parse(error.responseText).error
      views.alert error.message, () =>
        @trigger("mypres")
    presentation.fetch()

  edit: (model, options, force_save_btn_enabled = false) ->
    @clear_dirty()

    model.unbind "change", @edit

    @edit_view = new views.PresentationEditView(model: model, @prsntz, @video_backends, @slide_backends)
    @edit_view.render()
    @$el.html @edit_view.el

    @edit_view.bind "presentation_title", (title, published) =>
      @navigation_view.presentation_menu_title_save_btn utils.cut_string_at(title, 30), published
    @edit_view.bind "disable_save_button", @disable_save_button
    @edit_view.bind "enable_save_button", @enable_save_button
    @edit_view.bind "rendered", () =>
      @enable_save_button() if force_save_btn_enabled

  save: (preview) ->
    presentation_id = @edit_view.save()
    if preview? and preview
      window.open "#{user_catalog}/#{presentation_id}?preview", "preview"

  enable_save_button: () ->
    @set_dirty()
    @navigation_view.enable_save_button()

  disable_save_button: () ->
    @clear_dirty()
    @navigation_view.disable_save_button()

  set_dirty: () ->
    @dirty = true

  clear_dirty: () ->
    @dirty = false

@views.AppView = AppView
