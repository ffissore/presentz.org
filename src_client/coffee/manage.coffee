jQuery ->
  class Manage extends Backbone.View
    el: $("body")

    render: ->
      dust.render "prova", @model.toJSON(), (err, output) =>
        $(@el).html output
      @