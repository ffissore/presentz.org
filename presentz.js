/*
 * Presents - A web library to show video/slides presentations
 * 
 * Copyright (C) 2011 Federico Fissore
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

var chapter = 0;
var howManyChapters = 0;
var totalDuration = 0;
var interval;
var intervalSet = false;
var changeVideoSource;
var update_properties;
var wouldPlay = false;

function init() {
  if ((typeof presentation) == "undefined") {
    alert("NO presentation defined");
    return;
  }
  if (presentation.chapters.length == 0) {
    alert("NO chapters defined");
    return;
  }

  howManyChapters = presentation.chapters.length;
  var chapterIndex = 0;
  var agenda = "";
  for (chapterIndex in presentation.chapters) {
    totalDuration += presentation.chapters[chapterIndex].duration;
  }

  var widths = computeBarWidths(100, true);
  for (chapterIndex in presentation.chapters) {
    agenda += "<div title='" + presentation.chapters[chapterIndex].title + "'  style='width: " + widths[chapterIndex] + "%' onclick='changeChapter("
        + chapterIndex + ", true);'>&nbsp;</div>";
  }

  // $("#agendaContainer").html(agenda);
  // $("#agendaContainer div[title]").tooltip( {
  // effect : "fade",
  // opacity : 0.7
  // });

  var currentChapter = presentation.chapters[chapter];

  var firstVideoUrl = currentChapter.media.video.url.toLowerCase();
  if (firstVideoUrl.indexOf("http://youtu.be") != -1) {
    changeVideoSource = changeVideoYoutube;
    update_properties = update_properties_youtube;
  } else if (firstVideoUrl.indexOf("http://vimeo.com") != -1) {
    changeVideoSource = changeVideoVimeo;
    update_properties = update_properties_vimeo;
  } else {
    changeVideoSource = changeVideoHtml5;
    update_properties = update_properties_html5;
  }

  changeChapter(chapter, false);
}

function computeBarWidths(max) {
  var chapterIndex = 0;
  var widths = new Array();
  var sumOfWidths = 0;
  for (chapterIndex in presentation.chapters) {
    var width = presentation.chapters[chapterIndex].duration * max / totalDuration;
    if (width == 0) {
      width = 1;
    }
    widths[chapterIndex] = width;
    sumOfWidths += width;
  }

  var maxIndex = 0;
  if (sumOfWidths > (max - 1)) {
    for (chapterIndex in presentation.chapters) {
      if (widths[chapterIndex] > widths[maxIndex]) {
        maxIndex = chapterIndex;
      }
    }
  }
  widths[maxIndex] = widths[maxIndex] - (sumOfWidths - (max - 1));
  return widths;
}

function changeChapter(chapterIndex, play) {
  chapter = chapterIndex;
  changeSlide(presentation.chapters[chapter].media.slides[0].slide);
  changeVideoSource(presentation.chapters[chapter].media.video, play);

  // var i = 0;
  // for (i = 0; i < howManyChapters; i++) {
  // $("#agendaContainer > div")[i].setAttribute("class", "agendaunselected");
  // }
  // $("#agendaContainer > div")[chapter].setAttribute("class",
  // "agendaselected");
}

function changeSlide(slideData) {
  $("#slideContainer").empty();
  $("#slideContainer").append("<img width='100%' heigth='100%' src='" + slideData.url + "'>");
}

function changeVideoHtml5(videoData, play) {
  if ($("#videoContainer").children().length == 0) {
    var videoHtml = "<video controls preload='none' src='" + videoData.url + "' width='100%' heigth='100%'></video>";
    $("#videoContainer").append(videoHtml);

    var video = $("#videoContainer > video")[0];
    video.addEventListener("play", handleEventHtml5, false);
    video.addEventListener("pause", handleEventHtml5, false);
    video.addEventListener("ended", handleEventHtml5, false);
  } else {
    var video = $("#videoContainer > video")[0];
    video.setAttribute("src", videoData.url);
  }

  var video = $("#videoContainer > video")[0];
  video.load();

  if (play) {
    if (!intervalSet) {
      startTimeChecker();
    }
    video.play();
  }
}

function changeVideoYoutube(videoData, play) {
  var movieUrl = "http://www.youtube.com/e/" + videoData.url.substr(videoData.url.lastIndexOf("/") + 1) + "?enablejsapi=1&playerapiid=ytplayer";
  if ($("#videoContainer").children().length == 0) {
    $("#videoContainer").append("<div id='youtubecontainer'></div>");
    var params = {
      allowScriptAccess : "always"
    };
    var atts = {
      id : "ytplayer"
    };
    swfobject.embedSWF(movieUrl, "youtubecontainer", "425", "356", "8", null, null, params, atts);
  } else {
    var video = document.getElementById("ytplayer");
    video.cueVideoByUrl(movieUrl);
  }

  if (play) {
    if (!intervalSet) {
      startTimeChecker();
    }
    var video = document.getElementById("ytplayer");
    video.playVideo();
  }
}

function changeVideoVimeo(videoData, play) {
  var movieUrl = "http://vimeo.com/moogaloop.swf?clip_id=" + videoData.url.substr(videoData.url.lastIndexOf("/") + 1);
  $("#videoContainer").empty();
  $("#videoContainer").append("<div id='vimeoContainer'></div>");

  var params = {
    allowscriptaccess : "always",
    allowfullscreen : "true",
    flashvars : "api=1&player_id=vimeoplayer&api_ready=onVimeoPlayerReady&js_ready=onVimeoPlayerReady",
    scalemode : "noscale"
  };
  var atts = {
    id : "vimeoplayer"
  };
  swfobject.embedSWF(movieUrl, "vimeoContainer", "500", "360", "8", null, null, params, atts);
  wouldPlay = play;
}

function onYouTubePlayerReady(id) {
  document.getElementById(id).addEventListener("onStateChange", "handleEventYouTube");
}

function onVimeoPlayerReady(id) {
  var video = document.getElementById(id);
  video.api_addEventListener("play", "handleEventVimeo");
  video.api_addEventListener("pause", "handleEventVimeo");
  video.api_addEventListener("finish", "handleEventVimeo");

  if (wouldPlay) {
    wouldPlay = false;
    if (!intervalSet) {
      startTimeChecker();
    }
    video.api_play();
  }
}

function startTimeChecker() {
  clearInterval(interval);
  intervalSet = true;
  interval = setInterval(update_properties, 1000);
}

function stopTimeChecker() {
  clearInterval(interval);
  intervalSet = false;
}

function handleEventHtml5(event) {
  if (event.type == "play") {
    startTimeChecker();
  } else if (event.type == "pause" || event.type == "ended") {
    stopTimeChecker();
  }
  if (event.type == "ended" && chapter < (howManyChapters - 1)) {
    changeChapter(chapter + 1, true);
  }
}

function handleEventYouTube(event) {
  if (event == 1) {
    startTimeChecker();
  } else if (event == 2 || event == 0) {
    stopTimeChecker();
  }
  if (event == 0 && chapter < (howManyChapters - 1)) {
    changeChapter(chapter + 1, true);
  }
}

function handleEventVimeo(id, event) {
  if (event == "play") {
    startTimeChecker();
  } else if (event == "pause" || event == "finish") {
    stopTimeChecker();
  }
  if (event == "finish" && chapter < (howManyChapters - 1)) {
    changeChapter(chapter + 1, true);
  }
}

function checkSlideChange(currentTime) {
  var slides = presentation.chapters[chapter].media.slides;
  var slideIndex;
  for (slideIndex = 0; slideIndex < slides.length; slideIndex++) {
    if (slides[slideIndex].slide.time < currentTime && slides[slideIndex].slide.url != $("#slideContainer > img")[0].src) {
      changeSlide(slides[slideIndex].slide);
    }
  }
}

function update_properties_html5() {
  console.debug($("#videoContainer > video")[0].currentTime);
  checkSlideChange($("#videoContainer > video")[0].currentTime);
}
function update_properties_youtube() {
  console.debug(document.getElementById("ytplayer").getCurrentTime());
  checkSlideChange(document.getElementById("ytplayer").getCurrentTime());
}
function update_properties_vimeo() {
  console.debug(document.getElementById("vimeoplayer").api_getCurrentTime());
  checkSlideChange(document.getElementById("vimeoplayer").api_getCurrentTime());
}

$(init);
