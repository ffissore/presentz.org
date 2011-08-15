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
  var Html5Video, Presentz, Video, Vimeo;
  Video = (function() {
    function Video(playState, pauseState, finishState, presentz) {
      this.playState = playState;
      this.pauseState = pauseState;
      this.finishState = finishState;
      this.presentz = presentz;
    }
    Video.prototype.handleEvent = function(event) {
      if (event === this.playState) {
        this.presentz.startTimeChecker();
      } else if (event === this.pauseState || event === this.finishState) {
        this.presentz.stopTimeChecker();
      }
      if (event === this.finishState && this.presentz.currentChapterIndex < (this.presentz.howManyChapters - 1)) {
        this.presentz.changeChapter(chapter + 1, true);
      }
    };
    return Video;
  })();
  Html5Video = (function() {
    function Html5Video(presentz) {
      this.video = new Video("play", "pause", "ended", presentz);
    }
    Html5Video.prototype.changeVideo = function(videoData, play) {
      var caller, eventHandler, video, videoHtml;
      if ($("#videoContainer").children().length === 0) {
        videoHtml = "<video controls preload='none' src='" + videoData.url + "' width='100%' heigth='100%'></video>";
        $("#videoContainer").append(videoHtml);
        caller = this;
        eventHandler = function(event) {
        caller.video.handleEvent(event.type);
      };
        video = $("#videoContainer > video")[0];
        video.onplay = eventHandler;
        video.onpause = eventHandler;
        video.onended = eventHandler;
      } else {
        video = $("#videoContainer > video")[0];
        video.setAttribute("src", videoData.url);
      }
    };
    Html5Video.prototype.currentTime = function() {
      return $("#videoContainer > video")[0].currentTime;
    };
    return Html5Video;
  })();
  Vimeo = (function() {
    var videoId;
    function Vimeo(presentz) {
      this.video = new Video("play", "pause", "finish", presentz);
      this.wouldPlay = false;
      this.currentTimeInSeconds = 0.0;
    }
    Vimeo.prototype.changeVideo = function(videoData, wouldPlay) {
      var ajaxCall;
      this.videoData = videoData;
      this.wouldPlay = wouldPlay;
      ajaxCall = {
        url: "http://vimeo.com/api/v2/video/" + (videoId(this.videoData)) + ".json",
        dataType: "jsonp",
        jsonpCallback: "presentz.videoPlugin.receiveVideoInfo"
      };
      $.ajax(ajaxCall);
    };
    videoId = function(videoData) {
      return videoData.url.substr(videoData.url.lastIndexOf("/") + 1);
    };
    Vimeo.prototype.receiveVideoInfo = function(data) {
      var caller, iframe, movieUrl, onReady, videoHtml;
      movieUrl = "http://player.vimeo.com/video/" + (videoId(this.videoData)) + "?api=1&player_id=player_1";
      if ($("#videoContainer").children().length === 0) {
        videoHtml = "<iframe id='player_1' src='" + movieUrl + "' width='100%' height='" + data[0].height + "' frameborder='0'></iframe>";
        $("#videoContainer").append(videoHtml);
        iframe = $("#videoContainer iframe")[0];
        caller = this;
        onReady = function(id) {
        caller.onReady(id);
      };
        $f(iframe).addEvent("ready", onReady);
      } else {
        iframe = $("#videoContainer iframe")[0];
        iframe.src = movieUrl;
      }
    };
    Vimeo.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.video.url.toLowerCase().indexOf("http://vimeo.com") !== -1;
    };
    Vimeo.prototype.onReady = function(id) {
      var caller, video;
      video = $f(id);
      caller = this;
      video.addEvent("play", function() {
      caller.video.handleEvent("play");
    });
      video.addEvent("pause", function() {
      caller.video.handleEvent("pause");
    });
      video.addEvent("finish", function() {
      caller.video.handleEvent("finish");
    });
      video.addEvent("playProgress", function(data) {
      caller.currentTimeInSeconds = data.seconds;
    });
    };
    Vimeo.prototype.currentTime = function() {
      return this.currentTimeInSeconds;
    };
    return Vimeo;
  })();
  Presentz = (function() {
    function Presentz() {
      this.videoPlugins = [new Vimeo(this)];
      this.defaultVideoPlugin = new Html5Video(this);
    }
    Presentz.prototype.registerVideoPlugin = function(plugin) {
      this.videoPlugins.push(plugin);
    };
    Presentz.prototype.init = function(presentation) {
      var agenda, chapter, chapterIndex, plugin, videoPlugins, widths, _i, _len, _ref, _ref2;
      this.presentation = presentation;
      this.howManyChapters = this.presentation.chapters.length;
      this.currentChapterIndex = 0;
      _ref = this.presentation.chapters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chapter = _ref[_i];
        this.totalDuration += parseInt(chapter.duration);
      }
      widths = this.computeBarWidths(100, true);
      agenda = '';
      for (chapterIndex = 0, _ref2 = this.presentation.chapters.length - 1; 0 <= _ref2 ? chapterIndex <= _ref2 : chapterIndex >= _ref2; 0 <= _ref2 ? chapterIndex++ : chapterIndex--) {
        agenda += "<div title='" + this.presentation.chapters[chapterIndex].title + "' style='width: " + widths[chapterIndex] + "%' onclick='changeChapter(" + chapterIndex + ", true);'>&nbsp;</div>";
      }
      $("#agendaContainer").html(agenda);
      $("#agendaContainer div[title]").tooltip({
        effect: "fade",
        opacity: 0.7
      });
      videoPlugins = (function() {
        var _j, _len2, _ref3, _results;
        _ref3 = this.videoPlugins;
        _results = [];
        for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
          plugin = _ref3[_j];
          if (plugin.handle(this.presentation)) {
            _results.push(plugin);
          }
        }
        return _results;
      }).call(this);
      if (videoPlugins.length > 0) {
        this.videoPlugin = videoPlugins[0];
      } else {
        this.videoPlugin = this.defaultVideoPlugin;
      }
    };
    Presentz.prototype.computeBarWidths = function(max) {
      var chapter, chapterIndex, maxIndex, sumOfWidths, width, widths, _i, _j, _len, _len2, _ref, _ref2;
      chapterIndex = 0;
      widths = [];
      sumOfWidths = 0;
      chapterIndex = 0;
      _ref = this.presentation.chapters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chapter = _ref[_i];
        width = chapter.durationmax / this.totalDuration;
        if (width === 0) {
          width = 1;
        }
        widths[chapterIndex] = width;
        sumOfWidths += width;
        chapterIndex++;
      }
      maxIndex = 0;
      if (sumOfWidths > (max - 1)) {
        chapterIndex = 0;
        _ref2 = this.presentation.chapters;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          chapter = _ref2[_j];
          if (widths[chapterIndex] > widths[maxIndex]) {
            maxIndex = chapterIndex;
          }
          chapterIndex++;
        }
      }
      widths[maxIndex] = widths[maxIndex] - (sumOfWidths - (max - 1));
      return widths;
    };
    Presentz.prototype.changeChapter = function(chapterIndex, play) {
      var currentMedia;
      this.currentChapterIndex = chapterIndex;
      currentMedia = this.presentation.chapters[this.currentChapterIndex].media;
      this.changeSlide(currentMedia.slides[0].slide);
      this.videoPlugin.changeVideo(currentMedia.video, play);
    };
    Presentz.prototype.changeSlide = function(slideData) {
      if ($("#slideContainer img").length === 0) {
        $("#slideContainer").empty();
        $("#slideContainer").append("<img width='100%' heigth='100%' src='" + slideData.url + "'>");
      } else {
        $("#slideContainer img")[0].setAttribute("src", slideData.url);
      }
    };
    Presentz.prototype.checkSlideChange = function(currentTime) {
      var candidateSlide, slide, slides, _i, _len;
      slides = this.presentation.chapters[this.currentChapterIndex].media.slides;
      candidateSlide = void 0;
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        if (slide.slide.time < currentTime) {
          candidateSlide = slide.slide;
        }
      }
      if (candidateSlide !== void 0 && candidateSlide.url !== $("#slideContainer > img")[0].src) {
        this.changeSlide(candidateSlide);
      }
    };
    Presentz.prototype.startTimeChecker = function() {
      var caller, eventHandler;
      clearInterval(this.interval);
      this.intervalSet = true;
      caller = this;
      eventHandler = function() {
      caller.checkState();
    };
      this.interval = setInterval(eventHandler, 500);
    };
    Presentz.prototype.stopTimeChecker = function() {
      clearInterval(this.interval);
      this.intervalSet = false;
    };
    Presentz.prototype.checkState = function() {
      this.checkSlideChange(this.videoPlugin.currentTime());
    };
    return Presentz;
  })();
  window.Presentz = Presentz;
}).call(this);
