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

exec_for_each = (callable, elements, callback) ->
  return callback(undefined, elements) if elements.length is 0
  exec_times = 0
  for element in elements
    callable element, (err) ->
      return callback(err) if err?
      exec_times++
      return callback(undefined, elements) if exec_times is elements.length

cut_string_at = (str, size) ->
  if str? and str.length > size + 3
    return "#{str.substring(0, size)}..."
  str

remove_unwanted_fields_from = (obj, fields_to_remove) ->
  for key, value of obj
    delete obj[key] if key in fields_to_remove

ensure_only_wanted_fields_in = (obj, allowed_fields) ->
  for key, value of obj
    delete obj[key] unless key in allowed_fields

remove_unwanted_map_of_fields_from = (objtype, obj, map_of_fields_to_remove) ->
  return unless map_of_fields_to_remove[objtype]?
  fields_to_remove = map_of_fields_to_remove[objtype]
  remove_unwanted_fields_from obj, fields_to_remove

ensure_only_wanted_map_of_fields_in = (objtype, obj, map_of_allowed_fields) ->
  return unless map_of_allowed_fields[objtype]?
  allowed_fields = map_of_allowed_fields[objtype]
  ensure_only_wanted_fields_in obj, allowed_fields

visit_presentation = (presentation, func, fields_or_maps_of_fields) ->
  if func.length is 3
    apply_on = (objtype, obj) ->
      func.call null, objtype, obj, fields_or_maps_of_fields
  else
    apply_on = (objtype, obj) ->
      func.call null, obj, fields_or_maps_of_fields

  apply_on "presentation", presentation
  if presentation.comments?
    for comment in presentation.comments
      apply_on "comment", comment
      apply_on "user", comment.user if comment.user?

  return unless presentation.chapters?

  for chapter in presentation.chapters
    apply_on "chapter", chapter
    apply_on "video", chapter.video if chapter.video?
    if chapter.slides?
      for slide in chapter.slides
        apply_on "slide", slide
        if slide.comments?
          for comment in slide.comments
            apply_on "comment", comment
            apply_on "user", comment.user if comment.user?
  presentation

chars = "0123456789qwertyuiopasdfghjklzxcvbnm"
non_word_chars = /[\W]/g
short_words = /\b\w{2}\b/g

generate_id = (accent_fold, title) ->
  id = ""
  for idx in [0...5]
    c = parseInt(Math.random() * chars.length)
    id = id.concat(chars[c])

  return id unless title? and title isnt ""

  title = accent_fold(title.toLowerCase()).replace(non_word_chars, " ").replace(short_words, "").replace(/\s/g, "_")
  while title.indexOf("__") isnt -1
    title = title.replace("__", "_")
  title = title.replace(/[_]+$/, "")
  title = title.replace(/^[_]+/, "")

  title.concat("_", id)

is_url_valid = (url) ->
  url = "http://www.example.com#{url}" if url.indexOf("/") is 0
  uri = Uri(url)
  host = uri.host()
  path = uri.path()
  host? and host isnt "" and host.indexOf(".") isnt -1 and path? and path isnt ""

my_parse_float = (s, precision = 100) ->
  f = parseFloat(s)
  Math.round(f * precision) / precision

root = exports ? (@utils = {})

root.exec_for_each = exec_for_each
root.cut_string_at = cut_string_at
root.remove_unwanted_fields_from = remove_unwanted_fields_from
root.remove_unwanted_map_of_fields_from = remove_unwanted_map_of_fields_from
root.ensure_only_wanted_fields_in = ensure_only_wanted_fields_in
root.ensure_only_wanted_map_of_fields_in = ensure_only_wanted_map_of_fields_in
root.visit_presentation = visit_presentation
root.generate_id = generate_id
root.is_url_valid = is_url_valid
root.my_parse_float = my_parse_float