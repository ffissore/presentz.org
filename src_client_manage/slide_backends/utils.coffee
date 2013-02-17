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

make_new_slide = (url, time, public_url) ->
  new_slide =
    time: time
  
  if url?
    new_slide.url = url
  
  if public_url?
    new_slide.public_url = public_url
  else if new_slide.url?
    new_slide.public_url = new_slide.url
  
  new_slide

@slide_backends.make_new_slide = make_new_slide