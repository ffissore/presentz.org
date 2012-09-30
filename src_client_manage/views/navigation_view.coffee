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

class NavigationView extends Backbone.View

  el: $(".navbar > .navbar-inner > .container > .nav-collapse > .nav:first")

  reset: (highlight_idx) ->
    $("li:gt(1)", @$el).remove()
    $("li", @$el).removeClass "active"
    $("li", @$el).eq(highlight_idx).addClass "active" if highlight_idx?

  presentation_menu_title_save_btn: (title, published) ->
    $li = $("li", @$el)
    if $li.length < 3
      $li.removeClass "active"
      dust.render "_presentation_menu_title_save_btn", { title: title, published: published }, (err, out) =>
        return views.alert(err) if err?

        @$el.append(out)
        $("li.notify_save").hide()
        views.disable_forms()
    else
      $("a span", $li.eq(2)).text title

  enable_save_button: () ->
    $button = $("button", @$el)
    $button.attr "disabled", false
    $button.removeClass "disabled"
    $button.addClass "btn-warning"

  disable_save_button: () ->
    $button = $("button", @$el)
    $button.attr "disabled", true
    $button.addClass "disabled"
    $button.removeClass "btn-warning"
    $notify_save = $("li.notify_save")
    $notify_save.fadeIn "slow", () ->
      $notify_save.fadeOut "slow"

  save: (event) ->
    @trigger("save", $(event.target).hasClass("preview"))

  events:
    "click button.save": "save"

@views.NavigationView = NavigationView
