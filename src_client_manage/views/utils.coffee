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

loader_shown = true

scroll_top = () ->
  $(window).scrollTop(0)

loader_hide = () ->
  if loader_shown
    $("div.loader").hide()
    loader_shown = false

loader_show = () ->
  unless loader_shown
    $("body > .container").empty()
    $("div.loader").show()
    loader_shown = true

disable_forms = () ->
  $("form").submit () -> false

alert = (message, callback) ->
  $whoops = $("#whoops")
  return $whoops unless message?

  if typeof message is "string"
    $(".modal-body p:first", $whoops).text message
  else
    $(".modal-body p:first", $whoops).text message.message
    $(".modal-body p:last", $whoops).text message.stack

  if callback?
    $whoops.on "hidden", () ->
      $whoops.off "hidden"
      callback()
  $whoops.modal "show"

confirm = (message, callback) ->
  $confirm = $("#confirm")
  return $confirm unless message?

  $(".modal-body p", $confirm).text(message)
  $(".modal-footer button:last").click callback
  $confirm.modal "show"

@views.scroll_top = scroll_top
@views.loader_hide = loader_hide
@views.loader_show = loader_show
@views.disable_forms = disable_forms
@views.alert = alert
@views.confirm = confirm