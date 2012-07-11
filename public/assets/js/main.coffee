Controls =
  init: ->
    Controls.resize()

    $agenda_chapters = $("#controls .chapter")
    totalChapters = $agenda_chapters.length
    $agenda_chapters.each ->
      $instance = $(this)

      $instance.unbind "mouseenter"

      $instance.bind "mouseenter", ->
        selectedChapterWidth = $("#controls").width() + 1 - (totalChapters * 2)

        $agenda_chapters.not($instance).css "width", "2px"

        $instance.css("width", "#{selectedChapterWidth}px")
        $instance.find(".info").stop(true, true).delay(200).fadeIn(500)

      $instance.unbind "mouseleave"

      $instance.bind "mouseleave", ->
        Controls.restoreOriginalWidth()

    $chapters = $("#controls .chapter, #chapters ol li")
    $chapters.unbind "click"
    $chapters.bind "click", (e) ->
      $this = $(e.target)
      if $this.hasClass("comments") or $this.parent(".comments").length > 0
        show('#comments')
      else
        if !$this.is("a")
          #this is NOT a typo
          $this = $(".info .title a", this)
        prsntz.changeChapter(parseInt($this.attr("chapter_index")), parseInt($this.attr("slide_index")), true)

  restoreOriginalWidth: ->
    $("#controls .chapter").each ->
      $(this).find(".info").stop(true, true).hide()
    Controls.resize()

  resize: ->
    container_width = $("#controls").width()
    min_pixel_width = 2
    min_pixel_width_as_percentage = 100 * min_pixel_width / container_width
    $chapters = $("#controls .chapter")
    stolen_percentage = 0
    long_chapters_percentage = 0
    percentages = []

    #gather percentages and fix them if too low, accumulating stolen_percentage
    for chapter in $chapters
      $chapter = $(chapter)
      percentage = parseFloat($chapter.attr("percentage"))
      if percentage < min_pixel_width_as_percentage
        stolen_percentage += (min_pixel_width_as_percentage - percentage)
        percentage = min_pixel_width_as_percentage
      else
        long_chapters_percentage += percentage
      percentages.push(percentage)

    #resize chapters considering stolen_percentage and fix small chapters
    long_chapter_removed = false
    rounds = 0
    fix_as_many_small_chapters_as_possibile = ->
      long_chapter_removed = false
      percentage_to_remove_from_long_chapters = 100 * stolen_percentage / long_chapters_percentage
      for percentage in percentages
        if percentage > min_pixel_width_as_percentage
          new_percentage = percentage - (percentage / 100 * percentage_to_remove_from_long_chapters)
          if new_percentage < min_pixel_width_as_percentage
            min_pixel_width_as_percentage = percentage
            long_chapter_removed = true
            long_chapters_percentage -= percentage
      rounds++
    fix_as_many_small_chapters_as_possibile()
    fix_as_many_small_chapters_as_possibile() while long_chapter_removed and rounds < 6

    #now percentages should be correct, lets rewrite the original ones
    percentage_to_remove_from_long_chapters = 100 * stolen_percentage / long_chapters_percentage
    for idx in [0...percentages.length]
      percentage = percentages[idx]
      if percentage > min_pixel_width_as_percentage
        percentage -= (percentage / 100 * percentage_to_remove_from_long_chapters)
        percentages[idx] = percentage

    #percentages to pixels
    sum_of_pixels = 0
    pixel_widths = []
    for percentage in percentages
      chapter_pixels = Math.floor(container_width / 100 * percentage)
      sum_of_pixels += chapter_pixels
      pixel_widths.push(chapter_pixels)

    #some pixel may still be missing, lets spread them
    while (container_width - sum_of_pixels) > 0
      for idx in [0...pixel_widths.length] when (container_width - sum_of_pixels) > 0
        pixel_widths[idx] = pixel_widths[idx] + 1
        sum_of_pixels += 1

    #now give each div its width in pixel
    for idx in [0...pixel_widths.length]
      $($chapters[idx]).css("width", "#{pixel_widths[idx]}px")

DemoScroller =
  displayItemNumber: 3
  itemNumber: 0
  content_slider_w: null

  init: ->
    this.resize()

    this.itemNumber = $("#content_slider li.box4").length
    this.createNav() if this.itemNumber > this.displayItemNumber

  createNav: ->
    $this = this

    $('#slider').append("<div id=\"navigation_slider\"></div>")
    $('#navigation_slider').append("<ul></ul>")
    numLi = Math.ceil(this.itemNumber / this.displayItemNumber)

    for i in [0...numLi]
      item = $("<li><a href=\"#/demopage/#{(i + 1)}\" rel=\"#{i}\"></a></li>")
      $("#navigation_slider ul").append(item)

    ulWidth = (parseInt($("#navigation_slider ul li:first").width()) + parseInt($("#navigation_slider ul li:first").css("marginLeft").replace("px", "") * 2)) * numLi
    $("#navigation_slider ul").css("width", ulWidth + "px")

    $("#navigation_slider ul li a")
    .unbind("click")
    .bind("click", (e) ->
      e.preventDefault()
      $("#navigation_slider ul li a").removeClass()
      $(this).addClass("active")
      $this.moveScroll(parseInt($(this).attr("rel"))))


    $("a", "#navigation_slider ul li:first").trigger("click")

  moveScroll: (value) ->
    $("#content_slider").stop(true, false).animate({"left": -(value * $("#slider").width())}, 1200, "easeInOutQuart")

  resize: ->
    if $("#content_slider").length > 0
      this.content_slider_w = $("#content_slider li.box4").length * parseInt(parseInt($(".box4").css("width").replace("px", "")) + (parseInt($(".box4").css("margin-left").replace("px", "")) * 2))
      $("#content_slider").css("width", this.content_slider_w)

      $("#navigation_slider ul li a.active").click()

window.Controls = Controls
window.DemoScroller = DemoScroller

$().ready ->
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

  #PRESENTZ PLAYER
  if $("#presentation").length > 0
    Controls.init()

  $window = $(window)
  $window.unbind "resize"
  $window.bind "resize", () ->
    DemoScroller.resize() if $("#content_slider").length > 0
    Controls.resize() if $("#controls").length > 0
  return