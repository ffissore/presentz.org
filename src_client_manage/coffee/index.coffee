jQuery ->
  class Presentation extends Backbone.Model

    defaults:
      title: "No title set"
      thumb: "nothumb.png"

  class AuthoredPresentation extends Backbone.Collection

    model: Presentation

  class Manage extends Backbone.View
    el: $("body")

    initialize: ->
      _.bindAll(@)
      new AuthoredPresentation().fetch()
      @render()

    render: ->
      dust.render "prova", {}, (err, output) =>
        $(@el).append output
      @

  manage = new Manage()

Backbone.sync = () ->
  console.log arguments