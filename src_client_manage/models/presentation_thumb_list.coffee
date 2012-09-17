class PresentationThumbList extends Backbone.Collection

  url: "/m/api/presentations"

  model: models.PresentationThumb

  comparator: (presentation) ->
    presentation.get("title").toLowerCase()

@models.PresentationThumbList = PresentationThumbList