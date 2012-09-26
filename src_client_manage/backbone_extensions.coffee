"use strict"

Backbone.DeepModel::_upstream_set = Backbone.DeepModel::set
Backbone.Model::_upstream_set = Backbone.Model::set

override_set = (prototype) ->
  prototype.set = (key, value, options) ->
    if _.isObject(key) or !key?
      options = value
    
    options ?= {}
    options.skip_validation ?= true
    
    prototype._upstream_set.call(@, key, value, options)
  return
    
override_set(Backbone.DeepModel::)
override_set(Backbone.Model::)

Backbone.Model::_upstream_save = Backbone.Model::save

Backbone.Model::save = (key, value, options) ->
  return false if !@_validate({}, {})

  Backbone.Model::_upstream_save.call(@, key, value, options)