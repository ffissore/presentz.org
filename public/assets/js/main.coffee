DemoScroller =

  displayItemNumber: 3
  itemNumber: 0
  content_slider_w: null

  init: () ->
    DemoScroller.resize()

    DemoScroller.itemNumber = $("#content_slider li.box4").length
    DemoScroller.createNav() if DemoScroller.itemNumber > DemoScroller.displayItemNumber

  createNav: () ->
    $("#slider").append("<div id=\"navigation_slider\"></div>")
    $("#navigation_slider").append("<ul></ul>")
    numLi = Math.ceil(DemoScroller.itemNumber / DemoScroller.displayItemNumber)

    $navigation_slider_ul = $("#navigation_slider ul")
    for i in [0...numLi]
      item = $("<li><a href=\"#/demopage/#{(i + 1)}\" rel=\"#{i}\"></a></li>")
      $navigation_slider_ul.append(item)

    ulWidth = (parseInt($("#navigation_slider ul li:first").width()) + parseInt($("#navigation_slider ul li:first").css("marginLeft").replace("px", "") * 2)) * numLi
    $navigation_slider_ul.css("width", ulWidth + "px")

    $("#navigation_slider ul li a")
    .unbind("click")
    .bind("click", (e) ->
      e.preventDefault()
      $this = $(this)
      $("#navigation_slider ul li a").removeClass()
      $this.addClass("active")
      DemoScroller.moveScroll(parseInt($this.attr("rel"))))


    $("a", "#navigation_slider ul li:first").trigger("click")

  moveScroll: (value) ->
    $("#content_slider").stop(true, false).animate({"left": -(value * $("#slider").width())}, 1200, "easeInOutQuart")

  resize: () ->
    if $("#content_slider").length > 0
      DemoScroller.content_slider_w = $("#content_slider li.box4").length * parseInt(parseInt($(".box4").css("width").replace("px", "")) + (parseInt($(".box4").css("margin-left").replace("px", "")) * 2))
      $("#content_slider").css("width", DemoScroller.content_slider_w)

      $("#navigation_slider ul li a.active").click()

$().ready () ->
  #GENERAL BEHAVIORS
  if $("#home").length > 0
    $("h1 a, #menu ul li:first-child a")
    .unbind("click")
    .bind("click", (e) ->
      e.preventDefault()
      $.scrollTo.window().queue([]).stop()
      $.scrollTo(0, 1200, {easing: "easeInOutQuart", offset:
        {top: 0}}))

  $("#link_demos, .link_demos, #link_learn_more")
  .unbind("click")
  .bind("click", (e) ->
    e.preventDefault()
    $.scrollTo.window().queue([]).stop()
    $.scrollTo($(e.target).attr("href"), 1200, {easing: "easeInOutQuart", offset:
      {top: -60}}))

  $("#link_login, #link_login_in_comment")
  .unbind("click")
  .bind("click", (e) ->
    e.preventDefault()
    $("#login:not(:visible)").fadeIn("slow"))

  $("#content_login .close")
  .unbind("click")
  .bind("click", (e) ->
    e.preventDefault()
    $("#login:visible").fadeOut("fast"))

  #SEARCH INPUT
  $(".search input:first").each ->
    $(this)
    .data("default", $(this).val())
    .focus(->
      if $(this).val() == $(this).data("default")
        $(this).val("")
    )
    .blur(->
      $(this).val($.trim($(this).val()))
      if $(this).val() == $(this).data("default") || $(this).val() == ""
        $(this).val($(this).data("default")))

  $(".search form").submit ->
    value = $(".search input:first").val()
    pattern = /[ ,\n,\r]/g
    if value.replace(pattern, "").length > 0
      alert("SEARCHING: " + value)

  #SCROLLER DEMO
  if $("#content_slider").length > 0
    DemoScroller.init()

  $window = $(window)
  $window.unbind "resize"
  $window.bind "resize", () ->
    DemoScroller.resize() if $("#content_slider").length > 0
  return