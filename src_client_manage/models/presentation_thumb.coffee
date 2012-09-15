class PresentationThumb extends Backbone.DeepModel

  initialize: () ->
    _.bindAll @

    @bind "all", () ->
      console.log arguments

@models.PresentationThumb = PresentationThumb