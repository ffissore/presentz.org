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
  var Agenda, BlipTv, Html5Video, ImgSlide, NullAgenda, Presentz, Sizer, SlideShare, SwfSlide, Video, Vimeo, Youtube,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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

    function Html5Video(presentz, videoContainer) {
      this.presentz = presentz;
      this.videoContainer = videoContainer;
      this.video = new Video("play", "pause", "ended", this.presentz);
    }

    Html5Video.prototype.changeVideo = function(videoData, wouldPlay) {
      var availableWidth, playerOptions, videoHtml,
        _this = this;
      this.wouldPlay = wouldPlay;
      $("#" + this.videoContainer).empty();
      availableWidth = $("#" + this.videoContainer).width();
      videoHtml = "<video id='html5player' controls preload='none' src='" + videoData.url + "' width='" + availableWidth + "'></video>";
      $("#" + this.videoContainer).append(videoHtml);
      playerOptions = {
        enableAutosize: false,
        timerRate: 500,
        success: function(me) {
          _this.onPlayerLoaded(me);
        }
      };
      new MediaElementPlayer("#html5player", playerOptions);
    };

    Html5Video.prototype.onPlayerLoaded = function(player) {
      var eventHandler,
        _this = this;
      this.player = player;
      eventHandler = function(event) {
        _this.video.handleEvent(event.type);
      };
      player.addEventListener("play", eventHandler, false);
      player.addEventListener("pause", eventHandler, false);
      player.addEventListener("ended", eventHandler, false);
      this.player.load();
      if (this.wouldPlay) {
        if (!this.presentz.intervalSet) this.presentz.startTimeChecker();
        return this.player.play();
      }
    };

    Html5Video.prototype.adjustSize = function() {
      var newHeight;
      if (this.player.height !== $("#html5player").height()) {
        newHeight = $("#html5player").height();
        $("#" + this.videoContainer).height(newHeight);
        $(".mejs-container").height(newHeight);
        this.player.height = newHeight;
      }
    };

    Html5Video.prototype.currentTime = function() {
      return this.player.currentTime;
    };

    Html5Video.prototype.skipTo = function(time) {
      if (this.player && this.player.currentTime) {
        this.player.setCurrentTime(time);
        return true;
      }
      return false;
    };

    return Html5Video;

  })();

  Vimeo = (function() {
    var videoId;

    function Vimeo(presentz, videoContainer) {
      this.presentz = presentz;
      this.videoContainer = videoContainer;
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
      var height, iframe, movieUrl, onReady, videoHtml, width,
        _this = this;
      movieUrl = "http://player.vimeo.com/video/" + (videoId(this.videoData)) + "?api=1&player_id=vimeoPlayer";
      if ($("#" + this.videoContainer).children().length === 0) {
        width = $("#" + this.videoContainer).width();
        height = (width / data[0].width) * data[0].height;
        this.sizer = new Sizer(width, height, this.videoContainer);
        videoHtml = "<iframe id='vimeoPlayer' src='" + movieUrl + "' width='" + width + "' height='" + height + "' frameborder='0'></iframe>";
        $("#" + this.videoContainer).append(videoHtml);
        iframe = $("#" + this.videoContainer + " iframe")[0];
        onReady = function(id) {
          _this.onReady(id);
        };
        $f(iframe).addEvent("ready", onReady);
      } else {
        iframe = $("#" + this.videoContainer + " iframe")[0];
        iframe.src = movieUrl;
      }
    };

    Vimeo.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.video.url.toLowerCase().indexOf("http://vimeo.com") !== -1;
    };

    Vimeo.prototype.onReady = function(id) {
      var video,
        _this = this;
      video = $f(id);
      video.addEvent("play", function() {
        _this.video.handleEvent("play");
      });
      video.addEvent("pause", function() {
        _this.video.handleEvent("pause");
      });
      video.addEvent("finish", function() {
        _this.video.handleEvent("finish");
      });
      video.addEvent("playProgress", function(data) {
        return _this.currentTimeInSeconds = data.seconds;
      });
      video.addEvent("loadProgress", function(data) {
        return _this.loadedTimeInSeconds = parseInt(parseFloat(data.duration) * parseFloat(data.percent));
      });
      if (this.wouldPlay) {
        this.wouldPlay = false;
        if (!this.presentz.intervalSet) this.presentz.startTimeChecker();
        video.api("play");
      }
    };

    Vimeo.prototype.currentTime = function() {
      return this.currentTimeInSeconds;
    };

    Vimeo.prototype.skipTo = function(time) {
      var player;
      if (time <= this.loadedTimeInSeconds) {
        player = $f($("#" + this.videoContainer + " iframe")[0]);
        player.api("seekTo", time);
        return true;
      }
      return false;
    };

    Vimeo.prototype.adjustSize = function() {
      var iframe, newSize;
      newSize = this.sizer.optimalSize();
      iframe = $("#" + this.videoContainer + " iframe");
      if (iframe.width() !== newSize.width) {
        iframe.width(newSize.width);
        iframe.height(newSize.height);
      }
    };

    return Vimeo;

  })();

  Youtube = (function() {
    var videoId;

    function Youtube(presentz, videoContainer) {
      this.presentz = presentz;
      this.videoContainer = videoContainer;
      this.video = new Video(1, 2, 0, this.presentz);
      this.sizer = new Sizer(425, 356, this.videoContainer);
      window.onYouTubePlayerReady = this.onYouTubePlayerReady;
    }

    Youtube.prototype.changeVideo = function(videoData, wouldPlay) {
      var atts, movieUrl, params;
      this.wouldPlay = wouldPlay;
      movieUrl = "http://www.youtube.com/e/" + (videoId(videoData)) + "?enablejsapi=1&autohide=1&fs=1&playerapiid=ytplayer";
      if ($("#" + this.videoContainer).children().length === 0) {
        $("#" + this.videoContainer).append("<div id='youtubecontainer'></div>");
        params = {
          allowScriptAccess: "always",
          allowFullScreen: true
        };
        atts = {
          id: "ytplayer"
        };
        swfobject.embedSWF(movieUrl, "youtubecontainer", "" + this.sizer.startingWidth, "" + this.sizer.startingHeight, "8", null, null, params, atts);
      } else {
        this.player.cueVideoByUrl(movieUrl);
      }
      if (this.wouldPlay && (this.player != null)) {
        if (!this.presentz.intervalSet) this.presentz.startTimeChecker();
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
        if (!presentz.intervalSet) presentz.startTimeChecker();
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

    function BlipTv(presentz, videoContainer) {
      this.presentz = presentz;
      this.video = new Html5Video(this.presentz, videoContainer);
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
      this.skipTo = this.video.skipTo;
    };

    BlipTv.prototype.handle = function(presentation) {
      return presentation.chapters[0].media.video.url.toLowerCase().indexOf("http://blip.tv") !== -1;
    };

    BlipTv.prototype.adjustSize = function() {
      this.video.adjustSize();
    };

    BlipTv.prototype.currentTime = function() {
      return this.video.currentTime();
    };

    BlipTv.prototype.skipTo = function(time) {
      return this.video.skipTo(time);
    };

    return BlipTv;

  })();

  ImgSlide = (function() {

    function ImgSlide(slideContainer) {
      this.slideContainer = slideContainer;
      this.preloadedSlides = [];
    }

    ImgSlide.prototype.changeSlide = function(slide) {
      var slideContainer;
      if ($("#" + this.slideContainer + " img").length === 0) {
        slideContainer = $("#" + this.slideContainer);
        slideContainer.empty();
        slideContainer.append("<img width='100%' height='100%' src='" + slide.url + "'>");
      } else {
        $("#" + this.slideContainer + " img")[0].setAttribute("src", slide.url);
      }
    };

    ImgSlide.prototype.adjustSize = function() {
      var img, newSize, slideContainer;
      if (!(this.sizer != null)) {
        slideContainer = $("#" + this.slideContainer);
        this.sizer = new Sizer(slideContainer.width(), slideContainer.height(), this.slideContainer);
      }
      newSize = this.sizer.optimalSize();
      img = $("#" + this.slideContainer + " img");
      if (img.width() !== newSize.width) {
        img[0].setAttribute("width", newSize.width);
        return img[0].setAttribute("height", newSize.height);
      }
    };

    ImgSlide.prototype.preload = function(slides) {
      var image, images, slide, _i, _len, _ref;
      images = [];
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        if (!(!(_ref = slide.url, __indexOf.call(this.preloadedSlides, _ref) >= 0))) {
          continue;
        }
        image = new Image();
        image.src = slide.url;
        images.push(image);
        this.preloadedSlides.push(slide.url);
      }
      return images;
    };

    return ImgSlide;

  })();

  SlideShare = (function() {
    var slideNumber;

    function SlideShare(slideContainer) {
      this.slideContainer = slideContainer;
      this.currentSlide = 0;
      this.sizer = new Sizer(598, 480, this.slideContainer);
    }

    SlideShare.prototype.handle = function(slide) {
      return slide.url.toLowerCase().indexOf("http://www.slideshare.net") !== -1;
    };

    SlideShare.prototype.changeSlide = function(slide) {
      var atts, currentSlide, docId, flashvars, nextSlide, params, player;
      if ($("#" + this.slideContainer).children().length === 0) {
        $("#" + this.slideContainer).append("<div id='slidesharecontainer'></div>");
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

    SlideShare.prototype.preload = function() {};

    return SlideShare;

  })();

  SwfSlide = (function() {

    function SwfSlide(slideContainer) {
      this.slideContainer = slideContainer;
      this.sizer = new Sizer(598, 480, this.slideContainer);
      this.preloadedSlides = [];
    }

    SwfSlide.prototype.handle = function(slide) {
      return slide.url.toLowerCase().indexOf(".swf") !== -1;
    };

    SwfSlide.prototype.changeSlide = function(slide) {
      var atts, swfslide;
      if ($("#" + this.slideContainer + " object").length === 0) {
        $("#" + this.slideContainer).empty();
        $("#" + this.slideContainer).append("<div id='swfslidecontainer'></div>");
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

    SwfSlide.prototype.preload = function(slides) {
      var atts, index, slide, _i, _len, _ref,
        _this = this;
      index = 0;
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        if (!(!(_ref = slide.url, __indexOf.call(this.preloadedSlides, _ref) >= 0))) {
          continue;
        }
        $("#swfpreloadslide" + index).remove();
        $("#" + this.slideContainer).append("<div id='swfpreloadslidecontainer" + index + "'></div>");
        atts = {
          id: "swfpreloadslide" + index,
          style: "visibility: hidden; position: absolute; margin: 0 0 0 0; top: 0;"
        };
        swfobject.embedSWF(slide.url, "swfpreloadslidecontainer" + index, "1", "1", "8", null, null, null, atts, function() {
          return _this.preloadedSlides.push(slide.url);
        });
      }
    };

    return SwfSlide;

  })();

  Agenda = (function() {
    var computeBarWidths;

    function Agenda(agendaContainer) {
      this.agendaContainer = agendaContainer;
    }

    Agenda.prototype.build = function(presentation) {
      var agenda, chapter, chapterIndex, slideIndex, title, totalDuration, widths, _i, _len, _ref, _ref2, _ref3;
      totalDuration = 0;
      _ref = presentation.chapters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chapter = _ref[_i];
        totalDuration += Math.round(chapter.duration);
      }
      widths = computeBarWidths(totalDuration, $("#" + this.agendaContainer).width(), presentation.chapters);
      agenda = '';
      for (chapterIndex = 0, _ref2 = widths.length - 1; 0 <= _ref2 ? chapterIndex <= _ref2 : chapterIndex >= _ref2; 0 <= _ref2 ? chapterIndex++ : chapterIndex--) {
        for (slideIndex = 0, _ref3 = widths[chapterIndex].length - 1; 0 <= _ref3 ? slideIndex <= _ref3 : slideIndex >= _ref3; 0 <= _ref3 ? slideIndex++ : slideIndex--) {
          if (presentation.chapters[chapterIndex].media.slides[slideIndex].title) {
            title = presentation.chapters[chapterIndex].media.slides[slideIndex].title;
          } else {
            title = "Slide " + (slideIndex + 1);
          }
          agenda += "<div style='width: " + widths[chapterIndex][slideIndex] + "px' onclick='presentz.changeChapter(" + chapterIndex + ", " + slideIndex + ", true);'><div class='progress'></div><div class='info'>" + title + "</div></div>";
        }
      }
      $("#" + this.agendaContainer).html(agenda);
    };

    Agenda.prototype.select = function(presentation, chapterIndex, slideIndex) {
      var currentSlideIndex, index, _ref;
      $("#" + this.agendaContainer + " div.agendaselected").removeClass("agendaselected");
      currentSlideIndex = slideIndex;
      for (index = 0, _ref = chapterIndex - 1; 0 <= _ref ? index <= _ref : index >= _ref; 0 <= _ref ? index++ : index--) {
        if (chapterIndex - 1 >= 0) {
          currentSlideIndex += presentation.chapters[index].media.slides.length;
        }
      }
      $("#" + this.agendaContainer + " div:nth-child(" + (currentSlideIndex + 1) + ")").addClass("agendaselected");
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
          if (!(slides.length > 1)) continue;
          slideWidth = Math.round(clength * slides[slideIndex].time / chapter.duration - slideWidthSum) - 1;
          slideWidth = slideWidth > 0 ? slideWidth : 1;
          slideWidthSum += slideWidth + 1;
          widths[chapterIndex][slideIndex - 1] = slideWidth;
        }
        widths[chapterIndex][slides.length - 1] = clength - slideWidthSum - 1;
        chapterIndex++;
      }
      return widths;
    };

    return Agenda;

  })();

  NullAgenda = (function() {

    function NullAgenda() {}

    NullAgenda.prototype.build = function() {};

    NullAgenda.prototype.select = function() {};

    return NullAgenda;

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

    function Presentz(videoContainer, slideContainer, agendaContainer) {
      this.videoPlugins = [new Vimeo(this, videoContainer), new Youtube(this, videoContainer), new BlipTv(this, videoContainer)];
      this.slidePlugins = [new SlideShare(slideContainer), new SwfSlide(slideContainer)];
      this.defaultVideoPlugin = new Html5Video(this, videoContainer);
      this.defaultSlidePlugin = new ImgSlide(slideContainer);
      this.currentChapterIndex = -1;
      if (!(agendaContainer != null)) {
        this.agenda = new NullAgenda();
      } else {
        this.agenda = new Agenda(agendaContainer);
      }
    }

    Presentz.prototype.registerVideoPlugin = function(plugin) {
      this.videoPlugins.push(plugin);
    };

    Presentz.prototype.registerSlidePlugin = function(plugin) {
      this.slidePlugins.push(plugin);
    };

    Presentz.prototype.init = function(presentation) {
      this.presentation = presentation;
      this.howManyChapters = this.presentation.chapters.length;
      this.agenda.build(this.presentation);
      this.videoPlugin = this.findVideoPlugin();
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
      var candidateSlide, slide, slides, _i, _len;
      slides = this.presentation.chapters[this.currentChapterIndex].media.slides;
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        if (slide.time <= currentTime) candidateSlide = slide;
      }
      if ((candidateSlide != null) && this.currentSlide.url !== candidateSlide.url) {
        this.changeSlide(candidateSlide, this.currentChapterIndex, slides.indexOf(candidateSlide));
      }
    };

    Presentz.prototype.changeSlide = function(slide, chapterIndex, slideIndex) {
      var slides;
      this.currentSlide = slide;
      this.slidePlugin = this.findSlidePlugin(slide);
      this.slidePlugin.changeSlide(slide);
      slides = this.presentation.chapters[chapterIndex].media.slides;
      slides = slides.slice(slideIndex + 1, (slideIndex + 5) + 1 || 9e9);
      this.findSlidePlugin(slide).preload(slides);
      this.agenda.select(this.presentation, chapterIndex, slideIndex);
    };

    Presentz.prototype.findVideoPlugin = function() {
      var plugin, plugins;
      plugins = (function() {
        var _i, _len, _ref, _results;
        _ref = this.videoPlugins;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          plugin = _ref[_i];
          if (plugin.handle(this.presentation)) _results.push(plugin);
        }
        return _results;
      }).call(this);
      if (plugins.length > 0) return plugins[0];
      return this.defaultVideoPlugin;
    };

    Presentz.prototype.findSlidePlugin = function(slide) {
      var plugin, plugins;
      plugins = (function() {
        var _i, _len, _ref, _results;
        _ref = this.slidePlugins;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          plugin = _ref[_i];
          if (plugin.handle(slide)) _results.push(plugin);
        }
        return _results;
      }).call(this);
      if (plugins.length > 0) return plugins[0];
      return this.defaultSlidePlugin;
    };

    Presentz.prototype.startTimeChecker = function() {
      var timeChecker,
        _this = this;
      clearInterval(this.interval);
      this.intervalSet = true;
      timeChecker = function() {
        _this.videoPlugin.adjustSize();
        _this.slidePlugin.adjustSize();
        _this.checkState();
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
