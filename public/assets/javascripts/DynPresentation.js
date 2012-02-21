/*
Presents - A web library to show video/slides presentations

Copyright (C) 2011 Federico Fissore

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
*/
(function() {
  var importExternalJS, param, params, _i, _len;

  importExternalJS = function(param) {
    var ajaxCall, scriptUrl;
    scriptUrl = param.substr(2);
    ajaxCall = {
      url: scriptUrl,
      dataType: "jsonp",
      jsonpCallback: "initPresentz"
    };
    $.ajax(ajaxCall);
  };

  params = window.location.search.substring(1).split("&");

  for (_i = 0, _len = params.length; _i < _len; _i++) {
    param = params[_i];
    if (param.indexOf("p=") === 0 && param.length > 2) importExternalJS(param);
  }

}).call(this);
