###
Presentz.org - A website to publish presentations with video and slides synchronized.

Copyright (C) 2012 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

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