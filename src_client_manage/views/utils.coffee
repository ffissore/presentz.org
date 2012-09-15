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

@views.scroll_top = scroll_top
@views.loader_hide = loader_hide
@views.loader_show = loader_show
@views.disable_forms = disable_forms