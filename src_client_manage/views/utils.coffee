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