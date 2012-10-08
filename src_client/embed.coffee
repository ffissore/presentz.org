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

find_presentation_data = () ->
  scripts = document.getElementsByTagName("script")
  for idx in [scripts.length - 1..0]
    script = scripts[idx]
    url = script.getAttribute("data-presentation-url")
    title = script.getAttribute("data-presentation-title")
    container_id = script.getAttribute("data-presentation-container-id")
    if url? and title?
      if url.indexOf("?") isnt -1
        url = "#{url}&"
      else
        url = "#{url}?"
      url = "#{url}embed"
      result =
        origin: script.src.match(new RegExp("https?://[^/]*"))
        dom_element: script
        container_id: container_id
        url: url
        title: title
      return result
  throw new Error("Missing presentation data: there must be data-presentation-url and data-presentation-title attributes defined")

html_of = (pres) ->
  text = document.createTextNode(pres.title)
  a = document.createElement("a")
  a.href = "#"
  a.onclick = () ->
    open_frame(pres)
    false
  a.appendChild(text)
  div = document.createElement("div")
  div.appendChild(a)
  fragment = document.createDocumentFragment()
  fragment.appendChild(div)
  fragment

container_of = (pres) ->
  return document.getElementById(pres.container_id) if pres.container_id?
  return pres.dom_element.parentNode if pres.dom_element.parentNode.tagName.toUpperCase() isnt "HEAD"
  return document.body

resize = (iframe, div) ->
  width = Math.round(window.innerWidth * 0.8)
  height = Math.round(window.innerHeight * 0.8)

  iframe.width = width
  iframe.height = height

  left = Math.round((window.innerWidth - width) / 2)
  top = Math.round((window.innerHeight - height) / 2)

  shadow = "0 0 1em grey"
  div.style.cssText = "position: absolute; z-index: 9999; left: #{left}px; top: #{top}px; -webkit-box-shadow: #{shadow}; -mox-box-shadow: #{shadow}; box-shadow: #{shadow};"

open_frame = (pres) ->
  iframe = document.createElement("iframe")
  iframe.src = pres.url
  iframe.style.cssText = "border: 0px none;"

  div = document.createElement("div")

  div.id = "presentz_#{(Math.round(Math.random() * 1000000))}"
  div.appendChild(iframe)

  close_button_img = document.createElement("img")
  close_button_img.src = "#{pres.origin}/assets/img/close_button.png"

  close_button = document.createElement("div")
  close_button.style.cssText = "cursor: pointer; height: 29px; overflow: hidden; position: absolute; right: -15px; top: -15px; width: 29px;"
  close_button.appendChild(close_button_img)
  div.appendChild(close_button)

  resize(iframe, div)

  onresize = () ->
    resize(iframe, div)

  close_button_img.onclick = () ->
    div.parentNode.removeChild(div)
    if jQuery?
      jQuery(window).unbind("resize", onresize)

  if jQuery?
    jQuery(window).bind("resize", onresize)

  fragment = document.createDocumentFragment()
  fragment.appendChild(div)
  document.body.appendChild(fragment)


pres = find_presentation_data()
container_node = container_of pres
container_node.appendChild(html_of(pres))