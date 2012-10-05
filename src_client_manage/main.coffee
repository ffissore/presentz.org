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

jQuery () ->
  prsntz = new Presentz("#video", "450x400", "#slide", "450x400")

  video_backends = [new window.video_backends.Youtube(prsntz.availableVideoPlugins.youtube), new window.video_backends.Vimeo(prsntz.availableVideoPlugins.vimeo), new window.video_backends.Dummy(prsntz.availableVideoPlugins.html5)]
  slide_backends = [new window.slide_backends.SlideShare(prsntz.availableSlidePlugins.slideshare), new window.slide_backends.Speakerdeck(prsntz.availableSlidePlugins.speakerdeck), new window.slide_backends.Dummy(prsntz.availableSlidePlugins.image)]

  app = new window.views.AppView(prsntz, video_backends, slide_backends)
  router = new window.AppRouter(app)

  window.views.alert().modal(show: false)
  window.views.confirm().modal(show: false)

  $("ul.nav a").click (event) ->
    return true unless app.dirty
    window.views.confirm "You have unsaved changes. Are you sure you want to proceed?", () ->
      window.location.hash = event.target.hash
    false

  Backbone.history.start pushState: false, root: "/m/"
  $.jsonp.setup callbackParameter: "callback"
  mejs.MediaElementDefaults.pluginPath = "/assets/img/mediaelementjs/"