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
        return alert(err) if err?

        @$el.append(out)
        $("li.notify_save").hide()
        views.disable_forms()
    else
      $("a span", $li.eq(2)).text title

  mypres: (event) ->
    router.navigate "mypres", trigger: true unless $(event.currentTarget).parent().hasClass "active"

  make: (event) ->
    router.navigate "make", trigger: true unless $(event.currentTarget).parent().hasClass "active"

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
    @trigger("save")
    presentation_id = app.save()
    if $(event.target).hasClass("preview")
      window.open "#{user_catalog}/#{presentation_id}?preview", "preview"

  events:
    "click a[href=#mypres]": "mypres"
    "click a[href=#make]": "make"
    "click button.save": "save"

@views.NavigationView = NavigationView
