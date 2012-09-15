class Presentation extends Backbone.DeepModel

  urlRoot: "/m/api/presentations/"

  validate: @validation

  loaded: false
  loading: false
  slides_to_delete: []

  toJSON: () ->
    presentation = $.extend true, {}, @attributes

    utils.visit_presentation presentation, utils.remove_unwanted_fields_from, [ "onebased", "$idx", "$len", "_plugin" ]

  delete_slides = (slides, callback) ->
    return callback() if !slides? or slides.length is 0

    slide = slides.pop()

    delete_slides(slides, callback) unless slide["@rid"]?

    $.ajax
      type: "DELETE"
      url: "/m/api/delete_slide/#{slide["@rid"].substr(1)}"
      success: () ->
        delete_slides(slides, callback)
      error: () ->
        alert("An error occured while deleting the slides")

  save: (attributes, options) ->
    options ||= {}
    options.success = (model, resp) =>
      if @slides_to_delete.length is 0
        return @trigger("sync", model, resp)

      delete_slides @slides_to_delete, () =>
        @loading = false
        @loaded = false
        @fetch { success: () => @trigger("sync") }

    Backbone.DeepModel.prototype.save.call(this, attributes, options)

  initialize: () ->
    _.bindAll @

    @bind "change", () ->
      for chapter, chapter_idx in @get("chapters")
        chapter._index = chapter_idx
        for slide, slide_idx in chapter.slides
          slide._index = slide_idx
          slide._onebased_index = slide_idx + 1
      @loading = true

    @bind "error", (model, error) ->
      if _.isString(error)
        alert error
      else if error.status?
        alert "Error: (#{error.status}): #{error.responseText}"
      else if error.message?
        alert "Error: #{error.message}"
    @bind "all", (event) =>
      ###
      if @loaded and _.str.startsWith(event, "change")
        app.enable_save_button()
      if @loaded and event is "sync"
        app.disable_save_button()
      ###
      if event is "change"
        @loaded = true
      console.log arguments

    keys = (key for key, value of @attributes)

    if keys.length is 1 and keys[0] is "id"
      @fetch()
    else
      @set "id", utils.generate_id(@get("title"))
      @trigger("change", @, {})

@models.Presentation = Presentation