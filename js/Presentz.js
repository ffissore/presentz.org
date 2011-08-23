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
  var BlipTv, Html5Video, ImgSlide, Presentz, SlideShare, Video, Vimeo, Youtube;
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
        this.presentz.changeChapter(this.presentz.currentChapterIndex + 1, true);
      }
    };
    return Video;
  })();
  Html5Video = (function() {
    function Html5Video(presentz) {
      this.presentz = presentz;
      this.video = new Video("play", "pause", "ended", this.presentz);
    }
    Html5Video.prototype.changeVideo = function(videoData, play) {
      var caller, eventHandler, videoHtml;
      if ($("#videoContainer").children().length === 0) {
        videoHtml = "<video controls preload='none' src='" + videoData.url + "' width='100%'></video>";
        $("#videoContainer").append(videoHtml);
        caller = this;
        eventHandler = function(event) {
        caller.video.handleEvent(event.type);
      };
        this.player = $("#videoContainer > video")[0];
        this.player.onplay = eventHandler;
        this.player.onpause = eventHandler;
        this.player.onended = eventHandler;
      } else {
        this.player.setAttribute("src", videoData.url);
      }
      this.player.load();
      if (play) {
        if (!this.presentz.intervalSet) {
          this.presentz.startTimeChecker();
        }
        this.player.play();
      }
    };
    Html5Video.prototype.currentTime = function() {
      return presentz.videoPlugin.player.currentTime;
    };
    return Html5Video;
  })();
  Vimeo = (function() {
    var videoId;
    function Vimeo(presentz) {
      this.presentz = presentz;
      this.video = new Video("play", "pause", "finish", this.presentz);
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
      if (this.wouldPlay) {
        this.wouldPlay = false;
        if (!this.presentz.intervalSet) {
          this.presentz.startTimeChecker();
        }
        video.api("play");
      }
    };
    Vimeo.prototype.currentTime = function() {
      return this.currentTimeInSeconds;
    };
    return Vimeo;
  })();
  Youtube = (function() {
    var adjustVideoSize, videoId;
    function Youtube(presentz) {
      this.presentz = presentz;
      this.video = new Video(1, 2, 0, this.presentz);
      window.onYouTubePlayerReady = this.onYouTubePlayerReady;
    }
    Youtube.prototype.changeVideo = function(videoData, wouldPlay) {
      var atts, movieUrl, params;
      this.wouldPlay = wouldPlay;
      movieUrl = "http://www.youtube.com/e/" + (videoId(videoData)) + "?enablejsapi=1&playerapiid=ytplayer";
      if ($("#videoContainer").children().length === 0) {
        $("#videoContainer").append("<div id='youtubecontainer'></div>");
        params = {
          allowScriptAccess: "always"
        };
        atts = {
          id: "ytplayer"
        };
        swfobject.embedSWF(movieUrl, "youtubecontainer", "425", "356", "8", null, null, params, atts);
      } else {
        this.player.cueVideoByUrl(movieUrl);
      }
      if (this.wouldPlay && this.player !== void 0) {
        if (!this.presentz.intervalSet) {
          this.presentz.startTimeChecker();
        }
        this.player.playVideo();
      }
    };
    videoId = function(videoData) {
      return videoData.url.substr(videoData.url.lastIndexOf("/") + 1);
    };
    Youtube.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.video.url.toLowerCase().indexOf("http://youtu.be") !== -1;
    };
    Youtube.prototype.onYouTubePlayerReady = function(id) {
      presentz.videoPlugin.playerArray = $("#" + id);
      presentz.videoPlugin.player = presentz.videoPlugin.playerArray[0];
      presentz.videoPlugin.player.addEventListener("onStateChange", "presentz.videoPlugin.video.handleEvent");
      adjustVideoSize(presentz.videoPlugin.playerArray);
      if (presentz.videoPlugin.wouldPlay) {
        if (!presentz.intervalSet) {
          presentz.startTimeChecker();
        }
        presentz.videoPlugin.player.playVideo();
      }
    };
    adjustVideoSize = function(playerArray) {
      var newHeight, newWidth;
      newWidth = $("#videoContainer").width();
      newHeight = 0.837647059 * newWidth;
      playerArray.width(newWidth);
      playerArray.height(newHeight);
    };
    Youtube.prototype.currentTime = function() {
      return presentz.videoPlugin.player.getCurrentTime();
    };
    return Youtube;
  })();
  BlipTv = (function() {
    var videoId;
    function BlipTv(presentz) {
      this.presentz = presentz;
      this.video = new Video(1, 2, 0, this.presentz);
    }
    BlipTv.prototype.changeVideo = function(videoData, wouldPlay) {
      var movieUrl, script, scripts;
      this.wouldPlay = wouldPlay;
      movieUrl = "" + videoData.url + ".js?width=480&height=303&parent=bliptvcontainer";
      if ($("#videoContainer").children().length === 0) {
        $("#videoContainer").append("<div id='bliptvcontainer'></div>");
        script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = movieUrl;
        scripts = $("script");
        $(scripts[scripts.length - 1]).append(script);
        console.log($("script"));
      } else {
        throw "boh!";
      }
      if (this.wouldPlay && this.player !== void 0) {
        if (!this.presentz.intervalSet) {
          this.presentz.startTimeChecker();
        }
        this.player.play();
      }
    };
    videoId = function(videoData) {
      return videoData.url.substr(videoData.url.lastIndexOf("/") + 1);
    };
    BlipTv.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.video.url.toLowerCase().indexOf("http://blip.tv") !== -1;
    };
    BlipTv.prototype.onBlipTvPlayerAlmostReady = function() {
      var caller;
      this.player = document.getElementById("bliptvcontainer");
      caller = this;
      this.player.registerCallback("playerReady", function () {
        caller.onBlipTvPlayerReady();
    });
    };
    BlipTv.prototype.onBlipTvPlayerReady = function() {
      if (this.wouldPlay) {
        if (!this.presentz.intervalSet) {
          this.presentz.startTimeChecker();
        }
        this.player.play();
      }
    };
    BlipTv.prototype.currentTime = function() {
      return presentz.videoPlugin.player.getCurrentTime();
    };
    return BlipTv;
  })();
  ImgSlide = (function() {
    function ImgSlide() {}
    ImgSlide.prototype.changeSlide = function(slide) {
      if (this.slide === void 0) {
        $("#slideContainer").empty();
        $("#slideContainer").append("<img width='100%' src='" + slide.url + "'>");
        this.slide = $("#slideContainer img")[0];
      } else {
        this.slide.setAttribute("src", slide.url);
      }
    };
    ImgSlide.prototype.isCurrentSlideDifferentFrom = function(slide) {
      return this.slide.src.lastIndexOf(slide.url) === -1;
    };
    return ImgSlide;
  })();
  SlideShare = (function() {
    var slideNumber;
    function SlideShare() {
      this.currentSlide = 0;
    }
    SlideShare.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.slides[0].url.toLowerCase().indexOf("http://www.slideshare.net") !== -1;
    };
    SlideShare.prototype.changeSlide = function(slide) {
      var atts, currentSlide, docId, flashvars, nextSlide, params, player;
      if ($("#slideContainer").children().length === 0) {
        $("#slideContainer").append("<div id='slidesharecontainer'></div>");
        docId = slide.url.substr(slide.url.lastIndexOf("/") + 1, slide.url.lastIndexOf("#") - 1 - slide.url.lastIndexOf("/"));
        params = {
          allowScriptAccess: "always"
        };
        atts = {
          id: "slideshareplayer"
        };
        flashvars = {
          doc: docId,
          rel: 0
        };
        swfobject.embedSWF("http://static.slidesharecdn.com/swf/ssplayer2.swf", "slidesharecontainer", "598", "480", "8", null, flashvars, params, atts);
        this.currentSlide = 0;
      } else {
        player = $("#slideshareplayer")[0];
        nextSlide = slideNumber(slide);
        if (player.getCurrentSlide) {
          currentSlide = player.getCurrentSlide();
          if (nextSlide === (currentSlide + 1)) {
            player.next();
          } else {
            player.jumpTo(slideNumber(slide));
            this.currentSlide = player.getCurrentSlide();
          }
        }
      }
    };
    SlideShare.prototype.isCurrentSlideDifferentFrom = function(slide) {
      return slideNumber(slide) !== this.currentSlide;
    };
    slideNumber = function(slide) {
      return parseInt(slide.url.substr(slide.url.lastIndexOf("#") + 1));
    };
    return SlideShare;
  })();
  Presentz = (function() {
    var computeBarWidths;
    function Presentz() {
      this.videoPlugins = [new Vimeo(this), new Youtube(this), new BlipTv(this)];
      this.slidePlugins = [new SlideShare()];
      this.defaultVideoPlugin = new Html5Video(this);
      this.defaultSlidePlugin = new ImgSlide();
    }
    Presentz.prototype.registerVideoPlugin = function(plugin) {
      this.videoPlugins.push(plugin);
    };
    Presentz.prototype.registerSlidePlugin = function(plugin) {
      this.slidePlugins.push(plugin);
    };
    Presentz.prototype.init = function(presentation) {
      var agenda, chapter, chapterIndex, plugin, slidePlugins, totalDuration, videoPlugins, widths, _i, _len, _ref, _ref2;
      this.presentation = presentation;
      this.howManyChapters = this.presentation.chapters.length;
      if (this.presentation.title) {
        document.title = this.presentation.title;
      }
      this.currentChapterIndex = 0;
      totalDuration = 0;
      _ref = this.presentation.chapters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chapter = _ref[_i];
        totalDuration += parseInt(chapter.duration);
      }
      widths = computeBarWidths(totalDuration, $("#agendaContainer").width(), this.presentation.chapters);
      agenda = '';
      for (chapterIndex = 0, _ref2 = this.presentation.chapters.length - 1; 0 <= _ref2 ? chapterIndex <= _ref2 : chapterIndex >= _ref2; 0 <= _ref2 ? chapterIndex++ : chapterIndex--) {
        agenda += "<div title='" + this.presentation.chapters[chapterIndex].title + "' style='width: " + widths[chapterIndex] + "px' onclick='presentz.changeChapter(" + chapterIndex + ", true);'></div>";
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
      slidePlugins = (function() {
        var _j, _len2, _ref3, _results;
        _ref3 = this.slidePlugins;
        _results = [];
        for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
          plugin = _ref3[_j];
          if (plugin.handle(this.presentation)) {
            _results.push(plugin);
          }
        }
        return _results;
      }).call(this);
      if (slidePlugins.length > 0) {
        this.slidePlugin = slidePlugins[0];
      } else {
        this.slidePlugin = this.defaultSlidePlugin;
      }
    };
    computeBarWidths = function(duration, maxWidth, chapters) {
      var chapter, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = chapters.length; _i < _len; _i++) {
        chapter = chapters[_i];
        _results.push((chapter.duration * maxWidth / duration) - 10);
      }
      return _results;
    };
    Presentz.prototype.changeChapter = function(chapterIndex, play) {
      var currentMedia, index, _ref;
      this.currentChapterIndex = chapterIndex;
      currentMedia = this.presentation.chapters[this.currentChapterIndex].media;
      this.slidePlugin.changeSlide(currentMedia.slides[0]);
      this.videoPlugin.changeVideo(currentMedia.video, play);
      for (index = 1, _ref = $("#agendaContainer div").length; 1 <= _ref ? index <= _ref : index >= _ref; 1 <= _ref ? index++ : index--) {
        $("#agendaContainer div:nth-child(" + index + ")").removeClass("agendaselected");
      }
      $("#agendaContainer div:nth-child(" + (chapterIndex + 1) + ")").addClass("agendaselected");
    };
    Presentz.prototype.checkSlideChange = function(currentTime) {
      var candidateSlide, slide, slides, _i, _len;
      slides = this.presentation.chapters[this.currentChapterIndex].media.slides;
      candidateSlide = void 0;
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        if (slide.time < currentTime) {
          candidateSlide = slide;
        }
      }
      if (candidateSlide !== void 0 && this.slidePlugin.isCurrentSlideDifferentFrom(candidateSlide)) {
        this.slidePlugin.changeSlide(candidateSlide);
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
