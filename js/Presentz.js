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
  var Agenda, BlipTv, Html5Video, ImgSlide, Presentz, Sizer, SlideShare, SwfSlide, Video, Vimeo, Youtube;
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
        this.presentz.changeChapter(this.presentz.currentChapterIndex + 1, 0, true);
      }
    };
    return Video;
  })();
  Html5Video = (function() {
    function Html5Video(presentz) {
      this.presentz = presentz;
      this.video = new Video("play", "pause", "ended", this.presentz);
    }
    Html5Video.prototype.changeVideo = function(videoData, wouldPlay) {
      var availableWidth, caller, playerOptions, videoHtml;
      this.wouldPlay = wouldPlay;
      $("#videoContainer").empty();
      availableWidth = $("#videoContainer").width();
      videoHtml = "<video id='html5player' controls preload='none' src='" + videoData.url + "' width='" + availableWidth + "'></video>";
      $("#videoContainer").append(videoHtml);
      caller = this;
      playerOptions = {
        enableAutosize: false,
        timerRate: 500,
        success: function(me) {
          caller.onPlayerLoaded(me);
        }
      };
      new MediaElementPlayer("#html5player", playerOptions);
    };
    Html5Video.prototype.onPlayerLoaded = function(player) {
      var caller, eventHandler;
      this.player = player;
      caller = this;
      eventHandler = function(event) {
        caller.video.handleEvent(event.type);
      };
      player.addEventListener("play", eventHandler, false);
      player.addEventListener("pause", eventHandler, false);
      player.addEventListener("ended", eventHandler, false);
      this.player.load();
      if (this.wouldPlay) {
        if (!this.presentz.intervalSet) {
          this.presentz.startTimeChecker();
        }
        return this.player.play();
      }
    };
    Html5Video.prototype.adjustSize = function() {
      var newHeight;
      if (this.player.height !== $("#html5player").height()) {
        newHeight = $("#html5player").height();
        $("#videoContainer").height(newHeight);
        $(".mejs-container").height(newHeight);
        return this.player.height = newHeight;
      }
    };
    Html5Video.prototype.currentTime = function() {
      return this.player.currentTime;
    };
    Html5Video.prototype.skipTo = function(time) {
      if (this.player && this.player.currentTime) {
        this.player.currentTime = time;
        return true;
      }
      return false;
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
      var caller, height, iframe, movieUrl, onReady, videoHtml, width;
      movieUrl = "http://player.vimeo.com/video/" + (videoId(this.videoData)) + "?api=1&player_id=vimeoPlayer";
      if ($("#videoContainer").children().length === 0) {
        width = $("#videoContainer").width();
        height = (width / data[0].width) * data[0].height;
        videoHtml = "<iframe id='vimeoPlayer' src='" + movieUrl + "' width='" + width + "' height='" + height + "' frameborder='0'></iframe>";
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
        return caller.currentTimeInSeconds = data.seconds;
      });
      video.addEvent("loadProgress", function(data) {
        return caller.loadedTimeInSeconds = parseInt(parseFloat(data.duration) * parseFloat(data.percent));
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
    Vimeo.prototype.skipTo = function(time) {
      var player;
      if (time <= this.loadedTimeInSeconds) {
        player = $f($("#videoContainer iframe")[0]);
        player.api("seekTo", time);
        return true;
      }
      return false;
    };
    Vimeo.prototype.adjustSize = function() {};
    return Vimeo;
  })();
  Youtube = (function() {
    var videoId;
    function Youtube(presentz) {
      this.presentz = presentz;
      this.video = new Video(1, 2, 0, this.presentz);
      this.sizer = new Sizer(425, 356, "videoContainer");
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
        swfobject.embedSWF(movieUrl, "youtubecontainer", "" + this.sizer.startingWidth, "" + this.sizer.startingHeight, "8", null, null, params, atts);
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
      var youTube;
      youTube = presentz.videoPlugin;
      youTube.id = id;
      youTube.player = $("#" + id)[0];
      youTube.player.addEventListener("onStateChange", "presentz.videoPlugin.video.handleEvent");
      if (youTube.wouldPlay) {
        if (!presentz.intervalSet) {
          presentz.startTimeChecker();
        }
        youTube.player.playVideo();
      }
    };
    Youtube.prototype.adjustSize = function() {
      var newSize, player;
      newSize = this.sizer.optimalSize();
      player = $("#" + this.id);
      if (player.width() !== newSize.width) {
        player.width(newSize.width);
        player.height(newSize.height);
      }
    };
    Youtube.prototype.currentTime = function() {
      return this.player.getCurrentTime();
    };
    Youtube.prototype.skipTo = function(time) {
      if (this.player) {
        this.player.seekTo(time, true);
        return true;
      }
      return false;
    };
    return Youtube;
  })();
  BlipTv = (function() {
    function BlipTv(presentz) {
      this.presentz = presentz;
      this.video = new Html5Video(this.presentz);
    }
    BlipTv.prototype.changeVideo = function(videoData, wouldPlay) {
      var ajaxCall;
      this.wouldPlay = wouldPlay;
      ajaxCall = {
        url: videoData.url,
        dataType: "jsonp",
        data: "skin=json",
        jsonpCallback: "presentz.videoPlugin.receiveVideoInfo"
      };
      $.ajax(ajaxCall);
    };
    BlipTv.prototype.receiveVideoInfo = function(data) {
      var fakeVideoData;
      fakeVideoData = {
        url: data[0].Post.media.url
      };
      this.video.changeVideo(fakeVideoData, this.wouldPlay);
      this.player = this.video.player;
      this.adjustSize = this.video.adjustSize;
      this.currentTime = this.video.currentTime;
      this.skipTo = this.video.skipTo;
    };
    BlipTv.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.video.url.toLowerCase().indexOf("http://blip.tv") !== -1;
    };
    return BlipTv;
  })();
  ImgSlide = (function() {
    function ImgSlide() {}
    ImgSlide.prototype.changeSlide = function(slide) {
      var slideContainer;
      if ($("#slideContainer img").length === 0) {
        slideContainer = $("#slideContainer");
        slideContainer.empty();
        slideContainer.append("<img width='100%' height='100%' src='" + slide.url + "'>");
        this.sizer = new Sizer(slideContainer.width(), slideContainer.width(), "slideContainer");
      } else {
        $("#slideContainer img")[0].setAttribute("src", slide.url);
      }
    };
    ImgSlide.prototype.adjustSize = function() {
      var img, newSize;
      newSize = this.sizer.optimalSize();
      img = $("#slideContainer img");
      if (img.width() !== newSize.width) {
        img[0].setAttribute("width", newSize.width);
        return img[0].setAttribute("height", newSize.height);
      }
    };
    return ImgSlide;
  })();
  SlideShare = (function() {
    var slideNumber;
    function SlideShare() {
      this.currentSlide = 0;
      this.sizer = new Sizer(598, 480, "slideContainer");
    }
    SlideShare.prototype.handle = function(slide) {
      return slide.url.toLowerCase().indexOf("http://www.slideshare.net") !== -1;
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
    slideNumber = function(slide) {
      return parseInt(slide.url.substr(slide.url.lastIndexOf("#") + 1));
    };
    SlideShare.prototype.adjustSize = function() {
      var currentSlide, newSize;
      newSize = this.sizer.optimalSize();
      currentSlide = $("#slideshareplayer")[0];
      if (currentSlide && currentSlide.width !== newSize.width) {
        currentSlide.width = newSize.width;
        return currentSlide.height = newSize.height;
      }
    };
    return SlideShare;
  })();
  SwfSlide = (function() {
    function SwfSlide() {
      this.sizer = new Sizer(598, 480, "slideContainer");
    }
    SwfSlide.prototype.handle = function(slide) {
      return slide.url.toLowerCase().indexOf(".swf") !== -1;
    };
    SwfSlide.prototype.changeSlide = function(slide) {
      var atts, swfslide;
      if ($("#slideContainer object").length === 0) {
        $("#slideContainer").empty();
        $("#slideContainer").append("<div id='swfslidecontainer'></div>");
        atts = {
          id: "swfslide"
        };
        swfobject.embedSWF(slide.url, "swfslidecontainer", "598", "480", "8", null, null, null, atts);
      } else {
        swfslide = $("#swfslide")[0];
        swfslide.data = slide.url;
      }
    };
    SwfSlide.prototype.adjustSize = function() {
      var currentSlide, newSize;
      newSize = this.sizer.optimalSize();
      currentSlide = $("#swfslide")[0];
      if (currentSlide && currentSlide.width !== newSize.width) {
        currentSlide.width = newSize.width;
        return currentSlide.height = newSize.height;
      }
    };
    return SwfSlide;
  })();
  Agenda = (function() {
    var computeBarWidths;
    function Agenda() {}
    Agenda.prototype.build = function(presentation) {
      var agenda, chapter, chapterIndex, slideIndex, title, totalDuration, widths, _i, _len, _ref, _ref2, _ref3;
      totalDuration = 0;
      _ref = presentation.chapters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chapter = _ref[_i];
        totalDuration += Math.round(chapter.duration);
      }
      widths = computeBarWidths(totalDuration, $("#agendaContainer").width(), presentation.chapters);
      agenda = '';
      for (chapterIndex = 0, _ref2 = widths.length - 1; 0 <= _ref2 ? chapterIndex <= _ref2 : chapterIndex >= _ref2; 0 <= _ref2 ? chapterIndex++ : chapterIndex--) {
        for (slideIndex = 0, _ref3 = widths[chapterIndex].length - 1; 0 <= _ref3 ? slideIndex <= _ref3 : slideIndex >= _ref3; 0 <= _ref3 ? slideIndex++ : slideIndex--) {
          if (presentation.chapters[chapterIndex].media.slides[slideIndex].title) {
            title = presentation.chapters[chapterIndex].media.slides[slideIndex].title;
          } else {
            title = "" + presentation.chapters[chapterIndex].title + " - Slide " + (slideIndex + 1);
          }
          agenda += "<div style='width: " + widths[chapterIndex][slideIndex] + "px' onclick='presentz.changeChapter(" + chapterIndex + ", " + slideIndex + ", true);'><div class='progress'></div><div class='info'>" + title + "</div></div>";
        }
      }
      $("#agendaContainer").html(agenda);
    };
    Agenda.prototype.select = function(presentation, chapterIndex, slideIndex) {
      var currentSlideIndex, index, _ref;
      $("#agendaContainer div.agendaselected").removeClass("agendaselected");
      currentSlideIndex = slideIndex;
      for (index = 0, _ref = chapterIndex - 1; 0 <= _ref ? index <= _ref : index >= _ref; 0 <= _ref ? index++ : index--) {
        if (chapterIndex - 1 >= 0) {
          currentSlideIndex += presentation.chapters[index].media.slides.length;
        }
      }
      $("#agendaContainer div:nth-child(" + (currentSlideIndex + 1) + ")").addClass("agendaselected");
    };
    computeBarWidths = function(duration, maxWidth, chapters) {
      var chapter, chapterIndex, clength, slideIndex, slideWidth, slideWidthSum, slides, widths, _i, _len, _ref;
      widths = new Array();
      chapterIndex = 0;
      for (_i = 0, _len = chapters.length; _i < _len; _i++) {
        chapter = chapters[_i];
        widths[chapterIndex] = new Array();
        clength = Math.round((chapter.duration * maxWidth / duration) - 1);
        slideWidthSum = 0;
        slides = chapter.media.slides;
        for (slideIndex = 1, _ref = slides.length - 1; 1 <= _ref ? slideIndex <= _ref : slideIndex >= _ref; 1 <= _ref ? slideIndex++ : slideIndex--) {
          if (slides.length > 1) {
            slideWidth = Math.round(clength * slides[slideIndex].time / chapter.duration - slideWidthSum) - 1;
            slideWidth = slideWidth > 0 ? slideWidth : 1;
            slideWidthSum += slideWidth + 1;
            widths[chapterIndex][slideIndex - 1] = slideWidth;
          }
        }
        widths[chapterIndex][slides.length - 1] = clength - slideWidthSum - 1;
        chapterIndex++;
      }
      return widths;
    };
    return Agenda;
  })();
  Sizer = (function() {
    function Sizer(startingWidth, startingHeight, containerName) {
      this.startingWidth = startingWidth;
      this.startingHeight = startingHeight;
      this.containerName = containerName;
    }
    Sizer.prototype.optimalSize = function() {
      var containerWidth, newHeight, newWidth, result;
      newHeight = $(window).height() - ($("div.container div.header").height() + $("div.container div.controls").height()) * 2;
      newWidth = Math.round(this.startingWidth / this.startingHeight * newHeight);
      containerWidth = $("#" + this.containerName).width();
      if (newWidth > containerWidth) {
        newWidth = containerWidth;
        newHeight = Math.round(this.startingHeight / this.startingWidth * newWidth);
      }
      result = {
        width: newWidth,
        height: newHeight
      };
      return result;
    };
    return Sizer;
  })();
  Presentz = (function() {
    function Presentz() {
      this.videoPlugins = [new Vimeo(this), new Youtube(this), new BlipTv(this)];
      this.slidePlugins = [new SlideShare(), new SwfSlide()];
      this.defaultVideoPlugin = new Html5Video(this);
      this.defaultSlidePlugin = new ImgSlide();
      this.currentChapterIndex = -1;
      this.agenda = new Agenda();
    }
    Presentz.prototype.registerVideoPlugin = function(plugin) {
      this.videoPlugins.push(plugin);
    };
    Presentz.prototype.registerSlidePlugin = function(plugin) {
      this.slidePlugins.push(plugin);
    };
    Presentz.prototype.init = function(presentation) {
      var plugin, videoPlugins;
      this.presentation = presentation;
      this.howManyChapters = this.presentation.chapters.length;
      if (this.presentation.title) {
        document.title = this.presentation.title;
      }
      this.agenda.build(this.presentation);
      videoPlugins = (function() {
        var _i, _len, _ref, _results;
        _ref = this.videoPlugins;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          plugin = _ref[_i];
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
    Presentz.prototype.changeChapter = function(chapterIndex, slideIndex, play) {
      var currentMedia, currentSlide;
      currentMedia = this.presentation.chapters[chapterIndex].media;
      currentSlide = currentMedia.slides[slideIndex];
      if (chapterIndex !== this.currentChapterIndex || this.videoPlugin.skipTo(currentSlide.time)) {
        this.changeSlide(currentSlide, chapterIndex, slideIndex);
        if (chapterIndex !== this.currentChapterIndex) {
          this.videoPlugin.changeVideo(currentMedia.video, play);
          this.videoPlugin.skipTo(currentSlide.time);
        }
        this.currentChapterIndex = chapterIndex;
      }
    };
    Presentz.prototype.checkSlideChange = function(currentTime) {
      var candidateSlide, slide, slideIndex, slides, _i, _len;
      slides = this.presentation.chapters[this.currentChapterIndex].media.slides;
      candidateSlide = void 0;
      slideIndex = -1;
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        if (slide.time < currentTime) {
          candidateSlide = slide;
          slideIndex++;
        }
      }
      if (candidateSlide !== void 0 && this.currentSlide.url !== candidateSlide.url) {
        this.changeSlide(candidateSlide, this.currentChapterIndex, slideIndex);
      }
    };
    Presentz.prototype.changeSlide = function(slide, chapterIndex, slideIndex) {
      this.currentSlide = slide;
      this.slidePlugin = this.findSlidePlugin(slide);
      this.slidePlugin.changeSlide(slide);
      this.agenda.select(this.presentation, chapterIndex, slideIndex);
    };
    Presentz.prototype.findSlidePlugin = function(slide) {
      var plugin, slidePlugins;
      slidePlugins = (function() {
        var _i, _len, _ref, _results;
        _ref = this.slidePlugins;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          plugin = _ref[_i];
          if (plugin.handle(slide)) {
            _results.push(plugin);
          }
        }
        return _results;
      }).call(this);
      if (slidePlugins.length > 0) {
        return slidePlugins[0];
      }
      return this.defaultSlidePlugin;
    };
    Presentz.prototype.startTimeChecker = function() {
      var caller, timeChecker;
      clearInterval(this.interval);
      this.intervalSet = true;
      caller = this;
      timeChecker = function() {
        caller.videoPlugin.adjustSize();
        caller.slidePlugin.adjustSize();
        caller.checkState();
      };
      this.interval = setInterval(timeChecker, 500);
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
