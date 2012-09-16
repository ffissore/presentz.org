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