/**
 *	PokkariPlayer class
 * 	subclasses @PokkariElement
 *	For writing of video player inline
 *	$Header: /usr/local/cvsroot/otter/html/scripts/pokkariPlayer.js,v 1.97 2010/09/28 22:41:33 jlerman Exp $
*/

if (typeof(PokkariPlayerOptions) == "undefined") {
	var PokkariPlayerOptions = {
		maxWidth: 480,
		maxHeight: 600,
		useShowPlayer: true,
		showPlayerOptions: {
			smallPlayerMode: true
		},
		useDocumentWrite: false,
		useScanScoutShim: false,
		baristaEndpoint: "http://barista.blip.tv:9393/barista/resolve",
		forceAspectWidth: false
	};
}

function PokkariPlayer(params) {
	this.wmode = "transparent";
}

PokkariPlayer.VERSION = '$Revision: 1.97 $';

PokkariPlayer.prototype = new Object();
PokkariPlayer.prototype.constructor = PokkariPlayer;

PokkariPlayer.setMaxWidth = function(m) {
	PokkariPlayerOptions.maxWidth = m;
}

PokkariPlayer.setMaxHeight = function(m) {
	PokkariPlayerOptions.maxHeight = m;
}

PokkariPlayer.initializeLegacyOptions = function() {
	if (typeof(PokkariPlayer.MAX_WIDTH) != "undefined")
		PokkariPlayerOptions.maxWidth = PokkariPlayer.MAX_WIDTH;

	if (typeof(PokkariPlayer.MAX_HEIGHT) != "undefined")
		PokkariPlayerOptions.maxHeight = PokkariPlayer.MAX_HEIGHT;

	if (typeof(PokkariPlayer.USE_SHOWPLAYER) != "undefined")
		PokkariPlayerOptions.useShowPlayer = PokkariPlayer.USE_SHOWPLAYER;

	if (typeof(PokkariPlayer.SHOWPLAYER_OPTIONS) != "undefined")
		PokkariPlayerOptions.showPlayerOptions = PokkariPlayer.SHOWPLAYER_OPTIONS;

	if (typeof(PokkariPlayer.USE_DOCUMENT_WRITE) != "undefined")
		PokkariPlayerOptions.useDocumentWrite = PokkariPlayer.USE_DOCUMENT_WRITE;

	if (typeof(PokkariPlayer.USE_SS_SHIM) != "undefined")
		PokkariPlayerOptions.useScanScoutShim = PokkariPlayer.USE_SS_SHIM;

	if (typeof(PokkariPlayer.BARISTA_ENDPOINT) != "undefined")
		PokkariPlayerOptions.baristaEndpoint = PokkariPlayer.BARISTA_ENDPOINT;
}

PokkariPlayer.eventContext = new Object();

PokkariPlayer.prototype.storeContext = function() {
	var key = (new Date()).getTime() + "-" + Math.floor(Math.random() * 1000);

	// TODO -- Write a method that periodically removes context past a certain age...

	PokkariPlayer.eventContext[key] = this;

	return key;
}

PokkariPlayer.retreiveContext = function(key) {
	var self = PokkariPlayer.eventContext[key];

	delete PokkariPlayer.eventContext[key];

	return self;
}

PokkariPlayer.prototype.destroy = function() {
}

PokkariPlayer.prototype.setSiteUrl = function(url) {
	this.site_url = url;
}

PokkariPlayer.prototype.getSiteUrl = function() {
	if(this.site_url) {
		return this.site_url;
	} else {
		var url = new Url(window.location.href);
		return "http://" + url.getServer();
	}
}

PokkariPlayer.prototype.setPrimaryMediaUrl = function(url) {
	this.primary_media_url = url;
}

PokkariPlayer.prototype.getPrimaryMediaUrl = function() {
	return this.primary_media_url;
}

PokkariPlayer.prototype.setPostsId = function(id) {
	this.posts_id = id;
}

PokkariPlayer.prototype.getPostsId = function() {
	return this.posts_id;
}

PokkariPlayer.prototype.setWidth = function(width) {
	if(width == -1) { width = 320 }
	this.width = parseInt(width);
}

PokkariPlayer.prototype.calculateResizedDimensions = function(width,height,targetWidth,targetHeight) {
	if (width>targetWidth || height>targetHeight) {
		var thisAspect = width/height;
		var targetAspect = targetWidth/targetHeight;
		var newWidth;
		var newHeight;

		if (thisAspect>=targetAspect || PokkariPlayerOptions.forceAspectWidth) {
			newWidth = targetWidth;
			newHeight = Math.floor(height * (targetWidth/width));
			if (this.controlsHeight) {
				newHeight += this.controlsHeight;
			}
		}
		else {
			newHeight = targetHeight;
			newWidth = Math.floor(width * (targetHeight/height));
		}

		return { width: newWidth, height: newHeight };
	}
	else {
		return { width: width, height: height };
	}
}

PokkariPlayer.prototype.getDimensions = function() {
	var width = Math.floor(this.width || 320);
	var height = Math.floor(this.height || 240);

	if (this.controlsHeight)
		height = height + this.controlsHeight;

	var dimensions = this.calculateResizedDimensions(width,height,PokkariPlayerOptions.maxWidth,PokkariPlayerOptions.maxHeight);
	return dimensions;
}


/**
* TODO - FIXME
* You MUST call getWidth() before getHeight() - otherwise you'll get
* the wrong aspect ratio.
* Should probably move this into a single getDimensions() method.
*/
PokkariPlayer.prototype.getWidth = function() {
	var dimensions = this.getDimensions();

	return dimensions.width;
}

PokkariPlayer.prototype.getPlayerWidth = function() {
	return this.getWidth();
}

PokkariPlayer.prototype.setHeight = function(height) {

	if(height == -1) { height = 240 }

	this.height = parseInt(height);
}

PokkariPlayer.prototype.getHeight = function() {
	var dimensions = this.getDimensions();

	return dimensions.height;
}

PokkariPlayer.prototype.getPlayerHeight = function() {
	return this.getHeight();
}

PokkariPlayer.prototype.setAutoPlay = function(ap) {
	this.autoPlay = ap;
}

PokkariPlayer.prototype.getAutoPlay = function() {
	if(this.autoPlay) {
		return true;
	} else {
		return false;
	}
}

PokkariPlayer.prototype.setPlayerTarget = function(obj) {
	this.playerTarget = obj;
}

PokkariPlayer.prototype.getPlayerTarget = function() {
	return this.playerTarget;
}

PokkariPlayer.prototype.getPlayer = function() {
	var embedId = this.getEmbedId();
	var objectId = this.getObjectId();

	return document.getElementById(embedId) ||
		document.getElementById(objectId);
}

PokkariPlayer.prototype.generateId = function(stub) {
	var name = stub;
	var i = 0;
	while (document.getElementById(name) && i<100)
		name = stub + (i++);

	return name;
}

PokkariPlayer.prototype.getObjectId = function() {
	if (!this.objectId) {
		this.objectId = this.generateId("video_player_object");
	}

	return this.objectId;
}

PokkariPlayer.prototype.getEmbedId = function() {
	if (!this.embedId) {
		this.embedId = this.generateId("video_player_embed");
	}

	return this.embedId;
}

PokkariPlayer.prototype.getTime = function() {
	var player = this.getPlayer();

	if (typeof(player) != "undefined" && player) {
		if (typeof(player.object) != "undefined" && typeof(player.object.CurrentPosition) != "undefined") {
			return player.object.CurrentPosition;
		}
		if (typeof(player.controls) != "undefined") {
			return player.controls.currentPosition;
		}
		else if (typeof(player.GetTime) != "undefined") {
			return player.GetTime() / player.GetTimeScale();
		}
		else if (typeof(player.GetVariable) != "undefined") {
			return player.GetVariable("videoCurrentTime");
		}
	}

	return this.getRenderedTime();
}

PokkariPlayer.prototype.getRenderedTime = function() {
	if (this.renderTime) {
		var t = new Date();

		var time = (t.getTime() - this.renderTime.getTime()) / 1000;

		return time;
	}

	return null;
}

PokkariPlayer.prototype.setTime = function() {
	throw("Cannot set time on generic embed");
}

PokkariPlayer.prototype.getDuration = function() {
	// TODO FIXME Ad player specific implementation.
	return this.duration;
}

PokkariPlayer.prototype.setDuration = function(value) {
	this.duration = value;
}

PokkariPlayer.prototype.getStatus = function() {
	var player = this.getPlayer();

	if (typeof(player) != "undefined" && player) {
		if (typeof(player.playState) != "undefined") {
			return PokkariWindowsPlayer.prototype.getStatus.apply(this);
		}
		else if (typeof(player.GetPluginStatus) != "undefined") {
			return PokkariQuicktimePlayer.prototype.getStatus.apply(this);
		}
		else if (typeof(player.GetVariable) != "undefined") {
			return PokkariFlashPlayer.prototype.getStatus.apply(this);
		}
	}

	var time = this.getTime();
	var duration = this.getDuration();

	if (time && duration) {
		return (time < duration) ? "Playing" : "Played";
	}

	return null;
}

PokkariPlayer.prototype.setStatus = function(value) {
	var player = this.getPlayer();

	if (typeof(player) != "undefined" && player) {
		if (typeof(player.playState) != "undefined") {
			return PokkariWindowsPlayer.prototype.setStatus.apply(this,arguments);
		}
		else if (typeof(player.GetPluginStatus) != "undefined") {
			return PokkariQuicktimePlayer.prototype.setStatus.apply(this,arguments);
		}
		else if (typeof(player.GetVariable) != "undefined") {
			return PokkariFlashPlayer.prototype.setStatus.apply(this,arguments);
		}
	}

	return null;
}

PokkariPlayer.prototype.pause = function() {
	this.setStatus("Paused");
}

PokkariPlayer.prototype.play = function() {
	this.setStatus("Playing");
}

PokkariPlayer.prototype.setPermalinkUrl = function(url) {
	this.permalinkUrl = url;
}

PokkariPlayer.prototype.getPermalinkUrl = function() {
	return this.permalinkUrl;
}

PokkariPlayer.prototype.setAdvertisingType = function(t) {
	this.adType = t;
}

PokkariPlayer.prototype.getAdvertisingType = function() {
	return this.adType;
}

PokkariPlayer.prototype.isAdProvidedBy = function(provider) {
	if (typeof(this.adType) == "string") {
		provider = provider.toLowerCase();
		var parts = this.adType.toLowerCase().split(/\s*,\s*/);
		for (var i=0; i<parts.length; i++) {
			if (parts[i] && parts[i] == provider)
				return true;
		}
	}

	return false;
}

PokkariPlayer.prototype.setPrerollAnimationUrl = function(value) {
	this.prerollAnimationUrl = value;
}

PokkariPlayer.prototype.getPrerollAnimationUrl = function() {
	return this.prerollAnimationUrl;
}

PokkariPlayer.prototype.setPostrollAnimationUrl = function(value) {
	this.postrollAnimationUrl = value;
}

PokkariPlayer.prototype.getPostrollAnimationUrl = function() {
	return this.postrollAnimationUrl;
}

PokkariPlayer.prototype.getPostsTitle = function() {
	return this.postsTitle;
}

PokkariPlayer.prototype.setPostsTitle = function(value) {
	this.postsTitle = value;
}

PokkariPlayer.prototype.getUsersId = function() {
	return this.usersId;
}

PokkariPlayer.prototype.setUsersId = function(value) {
	this.usersId = value;
}

PokkariPlayer.prototype.getUsersLogin = function() {
	return this.usersLogin;
}

PokkariPlayer.prototype.setUsersLogin = function(value) {
	this.usersLogin = value;
}

PokkariPlayer.prototype.getUsersFeedUrl = function() {
	return this.usersFeedUrl;
}

PokkariPlayer.prototype.setUsersFeedUrl = function(value) {
	this.usersFeedUrl = value;
}

PokkariPlayer.prototype.getTopics = function() {
	return this.topics;
}

PokkariPlayer.prototype.setTopics = function(value) {
	this.topics = value;
}

PokkariPlayer.prototype.getGuid = function() {
	return this.guid;
}

PokkariPlayer.prototype.setGuid = function(value) {
	this.guid = value;
}

PokkariPlayer.prototype.setThumbnail = function(value) {
	this.thumbnail = value;
}

PokkariPlayer.prototype.getThumbnail = function() {
	return this.thumbnail;
}

PokkariPlayer.prototype.getDescription = function() {
	return this.description;
}

PokkariPlayer.prototype.setDescription = function(value) {
	this.description = value;
}

PokkariPlayer.prototype.getWmode = function(value) {
	return this.wmode;
}

PokkariPlayer.prototype.setWmode = function(value) {
	this.wmode = value;
}

PokkariPlayer.prototype.setContentRating = function(value) {
	this.contentRating = value;
}

PokkariPlayer.prototype.getContentRating = function() {
	return this.contentRating;
}

PokkariPlayer.prototype.initializeFromPost = function(post) {
	this.setPrimaryMediaUrl(post.media.url);
    this.setPermalinkUrl(post.url);
    this.setAdvertisingType(post.advertising);
    this.setPostsId(post.postsId);
    this.setUsersId(post.usersId);
    this.setUsersLogin(post.login);
    this.setPostsTitle(post.title);
    this.setGuid(post.postsGuid);
	this.setDescription(post.description);
	this.setContentRating(post.contentRating);
    if (post.topics) {
    	this.setTopics(post.topics.join(', '));
    }

    if (post.media.width && post.media.height) {
    	this.setWidth(post.media.width);
    	this.setHeight(post.media.height);
    }
    else {
    	this.setWidth(320);
    	this.setHeight(240);
    }
}

PokkariPlayer.prototype.convertTimeToSeconds = function(timecode) {
	var time = timecode.replace(/;\d+$/,"");
	var timeParts = time.split(':');
	var result = timeParts[0]*60*60 + timeParts[1]*60 + timeParts[2];
	return result;
}

PokkariPlayer.prototype.convertSecondsToTime = function(s) {
	var d = new Date(s*1000);
	return d.toGMTString().substr(17,8);
}

PokkariPlayer.prototype.ensureSeconds = function(p) {
	if (isNaN(p)) { return this.convertTimeToSeconds(p); }
	else { return p; }
}

PokkariPlayer.prototype.ensureTime = function(p) {
	if (!isNaN(p)) { return this.convertSecondsToTime(p); }
	else { return p; }
}

PokkariPlayer.prototype.getDocumentWidth = function(d) {
	if (!d) d = document;

	if (d.body && typeof(d.body.clientWidth != "undefined"))
		return d.body.clientWidth;
	else if (d.documentElement && typeof(d.documentElement.clientWidth != "undefined"))
		return d.documentElement.clientWidth;
	else if (typeof(window.innerWidth) != "undefined")
		return window.innerWidth;
}

PokkariPlayer.prototype.getDocumentHeight = function(d) {
	if (!d) d = document;

	if (d.body && typeof(d.body.clientHeight != "undefined"))
		return d.body.clientHeight;
	else if (d.documentElement && typeof(d.documentElement.clientHeight != "undefined"))
		return d.documentElement.clientHeight;
	else if (typeof(window.innerHeight) != "undefined")
		return window.innerHeight;
}

PokkariPlayer.prototype.openFullscreen = function() {
	var width = window.screen.availWidth;
	var height = window.screen.availHeight;

	this.getPlayerTarget().innerHTML = "<b>Full-screen mode, make sure pop-ups aren't blocked</b>";

	this.fullWindow = window.open("","fullWindow","top=0,left=0,status=0,toolbar=0,titlebar=0,resizable=0,location=0,fullscreen=1,directories=0,width="+width+",height="+height);
	this.fullWindow.document.open("text/html","replace");
	this.fullWindow.document.write("<html><head><title>" + document.title +
		" (Full Screen)</title></head><body style='padding:0; margin:0; background-color: black;'>" +
		"<table width='100%' height='100%'><tr><td align='center' valign='middle'>" +
		"<div id='video_player' style='margin:auto'></div>" +
		"</td></tr></table></body></html>"
	);
	this.fullWindow.document.close();
	this.fullWindow.document.title = document.title + " (Full Screen)";
	var div = this.fullWindow.document.getElementById('video_player');
	this.setPlayerTarget(div);

	this.setFullscreenSize(this.fullWindow.document);
	this.setAutoPlay(true);

	this.render();
}

PokkariPlayer.prototype.setFullscreenSize = function(d)
{
	var width = this.getWidth();
	var height = this.getHeight();
	var doc_width = this.getDocumentWidth(d);
	var doc_height = this.getDocumentHeight(d);
	var aspect = width/height;

	// Safari won't let me set height = 100%, so gotta make up some number...
	if (doc_height < 100) {
		doc_height = window.screen.availHeight - 30;
	}

	if (!d) d = document;

	width = doc_width - (20 * aspect);
	height = Math.round(width / aspect);

	if (width < height || height > doc_height) {
		height = doc_height - 20;
		width = Math.round(height*aspect);
	}

	PokkariPlayerOptions.maxWidth = width;
	PokkariPlayerOptions.maxHeight = height;
	this.setWidth(width);
	this.setHeight(height);
}

PokkariPlayer.prototype.setAvailableMimeTypes = function(types) {
	this.availableMimeTypes = types;
}


PokkariPlayer.prototype.getHtml = function() {
	if(!this.getPrimaryMediaUrl()) {
		throw("Cannot render without primary media URL");
	}
        if(!this.getPlayerTarget()) {
                throw("Cannot render without player target");
        }

	var autoPlay = (this.getAutoPlay()) ? 'true' : 'false';

	var html = '<embed src="' + this.getPrimaryMediaUrl() + '" autoplay="' + autoPlay + '" controller="true" width="' + this.getPlayerWidth() + '" height="' + this.getPlayerHeight() + '" scale="aspect" EnableJavaScript="true" ></embed>';

	return html;
}

PokkariPlayer.prototype.render = function() {
	var html = this.getHtml();

	/*
        if (this.isAdProvidedBy("adjacent_blip")) {
		html += this.getBlipHtml();
	}
	else if (this.isAdProvidedBy("adjacent_scanscout") && !this.isAdProvidedBy("overlay_google")) {
		html += this.getScanScoutHtml();
       }*/

	if (PokkariPlayerOptions.useDocumentWrite) {
		document.write(html);
		var context = this.storeContext();
		var func = new Function("PokkariPlayer.retreiveContext('"+context+"').onRendered()");
		if (window.attachEvent) {
			window.attachEvent("onload",func);
		}
		else if (window.addEventListener) {
			window.addEventListener("load",func,true);
		}
	}
	else {
		this.getPlayerTarget().style.width = this.getPlayerWidth() + "px";
		this.getPlayerTarget().style.height = this.getPlayerHeight() + "px";
		this.getPlayerTarget().innerHTML = html;
		this.onRendered();
	}
}

PokkariPlayer.prototype.getScanScoutHtml = function() {
	this.hasScanScoutHtml = true;

	var html = '' +
	'<div id="ss_ads" style="height:60px">' +
	'</div>';

	return html;
}

PokkariPlayer.prototype.getBlipHtml = function() {
	var html = '<div id="blip_adPresentation" style="width:320px; display:none; padding:auto; margin:auto; text-align:center"></div>';

	this.hasBlipHtml = true;

	return html;
}

PokkariPlayer.prototype.getBlipHtmlCallback = function(params) {
	var element = document.getElementById("blip_adPresentation");
	var obj = params[0];
	element.innerHTML = obj.html;
	//this.adjustSizeForBlip();
	element.style.display = "block";

	// RE-adjust for variable height banners
	var context = this.storeContext();
	window.setTimeout("PokkariPlayer.retreiveContext('"+context+"').adjustSizeForBlip()",100);
}

PokkariPlayer.prototype.adjustSizeForScanScout = function() {
	var height = parseInt(this.getHeight());

	var newHeight = height + 80;

	this.getPlayerTarget().style.height = newHeight + "px";
}

PokkariPlayer.prototype.adjustSizeForBlip = function() {
	var element = document.getElementById("blip_adPresentation");
	var width = parseInt(this.getWidth());
	var height = parseInt(this.getHeight());
	var bannerHeight = element && element.offsetHeight ? element.offsetHeight : 30;
	var newWidth = (width > 320) ? width : 320;
	var newHeight = height + bannerHeight + 30;
	this.getPlayerTarget().style.width = newWidth + "px";
	this.getPlayerTarget().style.height = newHeight + "px";
}

PokkariPlayer.prototype.ss_play = function() {
	// We're outside of context here.   Use ss' context.
	var self = ss_videoPlayer;
	return self.play();
}

PokkariPlayer.prototype.ss_pause = function() {
	// We're outside of context here.   Use ss' context.
	var self = ss_videoPlayer;
	return self.pause();
}

PokkariPlayer.prototype.onRendered = function() {
	if (this.isAdProvidedBy("adjacent_scanscout") && this.hasScanScoutHtml) {
		if (self.ss_isLoaded == true) {
			this.adjustSizeForScanScout();

			self.ss_externalId = this.getGuid();
			self.ss_contentTitle = this.getPostsTitle();
			self.ss_contentDescription = this.getDescription();
			self.ss_contentKeywords = this.getTopics();
			self.ss_contentCategories = 'Default Category'; // TODO FIXME
			self.ss_partnerId = 970;
			self.ss_resumeVideoFunction = this.ss_play;
			self.ss_pauseVideoFunction = this.ss_pause;
			self.ss_getVideoPlayPositionFunction = ss_getPlayPositionPokkari;
			self.ss_getPlayStateFunction = ss_getPlayStatePokkari;
			self.ss_videoPlayer = this;
			self.ss_videoPlayerWidth = this.getWidth();
			self.ss_videoPlayerHeight = this.getHeight();
			self.ss_videoControlsHeight = this.controlsHeight;
			self.ss_videoAdMargin = 0;
			self.ss_adType = 'ticker';
			self.ss_playerId = this.getPlayer().id;
			self.ss_playerType = 'flashint';
			self.ss_contentURL = this.getPrimaryMediaUrl();
			self.ss_contentRating = this.getContentRating();

			if (self.ss_videoPlayerWidth == null ||
				self.ss_videoPlayerWidth == 0
			) {
				self.ss_videoPlayerWidth = 320;
			}

			if (self.ss_videoPlayerHeight == null ||
				self.ss_videoPlayerHeight == 0
			) {
				self.ss_videoPlayerHeight = 240 + self.ss_videoControlsHeight;
			}
			ss_start();
		}
	}
	else if (this.hasBlipHtml) {
		var barista = this.getBaristaUrl("adjacent","","blip","code","getBlipHtmlCallback");

		if (document.all && document.readyState && document.readyState != "complete") {
			document.write("<script type='text/javascript' src='" + barista + "'></script>");
		}
		else {
			var script = document.createElement("script");
			script.type = 'text/javascript';
			script.src = barista;
			var body = document.body || document.documentElement;
			body.appendChild(script);
		}
	}

	this.renderTime = new Date();
}


PokkariPlayer.prototype.getBaristaUrl = function(phase,format,source,flavor,callback,err_callback) {
	var url = new Url(window.location.href);
	var server = url.getServer();
	var parts = server.split('.');
	var domain = parts[parts.length-2] + "." + parts[parts.length-1];

	var barista = (PokkariPlayerOptions.baristaEndpoint || "http://barista." + domain + ":9393/barista/resolve/") +
		"?post_id=" + this.getPostsId() + "&format=" + format + "&phase=" + phase +
		"&source=" + source + "&flavor=" + flavor;

	if (typeof(callback) != "undefined") {
		var key = this.storeContext();

		barista += "&callback=" + escape("PokkariPlayer.retreiveContext('" + key + "')." + callback);

		if (typeof(err_callback) != "undefined") {
			barista += "&err_callback=" + escape("PokkariPlayer.retreiveContext('" + key + "')." + err_callback);
		}
		else {
			barista += "&err_callback=void";
		}
	}

	return barista;
}

PokkariPlayer.ChangeInstanceByMimeType = function(obj,type) {
	var newobj = PokkariPlayer.GetInstanceByMimeType(type);

	if (obj && newobj) {
		for (var i in obj) {
			if (typeof(obj[i]) == "function") {
				delete obj[i];
			}
		}
		for (var i in newobj) {
			if (typeof(newobj[i]) == "function") {
				obj[i] = newobj[i];
			}
		}
	}

	return obj;
}

PokkariPlayer.GetInstanceByMimeType = function(type,role) {
	PokkariPlayer.initializeLegacyOptions();
	var obj;
	
	if (PokkariShowPlayer.canPlayType(type) || (role && role.match(/^Blip/))) {
	    return new PokkariShowPlayer();
	}

        switch(type) {
                case 'video/quicktime':
			return new PokkariQuicktimePlayer();
                break;
		case 'video/mpg':
			return new PokkariQuicktimePlayer();
		break;
		case 'video/mpeg':
			return new PokkariQuicktimePlayer();
		break;
		case 'video/mp4':
			return new PokkariQuicktimePlayer();
		break;
		case 'video/x-dv':
			return new PokkariQuicktimePlayer();
		break;
		case 'video/x-flv':
			return PokkariPlayerOptions.useShowPlayer ? new PokkariShowPlayer() : new PokkariFlashPlayer();
		break;
		case 'video/x-flv,video/flv':
			return PokkariPlayerOptions.useShowPlayer ? new PokkariShowPlayer() : new PokkariFlashPlayer();
		break;
		case 'video/flv':
			return PokkariPlayerOptions.useShowPlayer ? new PokkariShowPlayer() : new PokkariFlashPlayer();
		break;
		case 'video/f4v,video/mp4':
			return new PokkariShowPlayer();
		break;
		case 'video/f4v':
			return new PokkariShowPlayer();
		break;
		case 'video/ms-wmv':
			return new PokkariWindowsPlayer();
		break;
		case 'video/x-ms-wmv':
			return new PokkariWindowsPlayer();
		break;
		case 'video/ms-wmv,video/x-ms-wmv':
			return new PokkariWindowsPlayer();
		break;
		case 'video/msvideo':
			return new PokkariWindowsPlayer();
		break;
		case 'application/ogg':
			return new PokkariTheoraPlayer();
		break;
		case 'video/theora':
			return new PokkariTheoraPlayer();
		break;
		case 'video/vnd.objectvideo':
			return new PokkariQuicktimePlayer();
		break;
		case 'image/jpeg':
			return new PokkariImagePlayer();
		break;
		case 'image/png':
			return new PokkariImagePlayer();
		break;
		case 'image/bmp':
			return new PokkariImagePlayer();
		break;
		case 'image/gif':
			return new PokkariImagePlayer();
		break;
		case 'audio/mpeg':
			return new PokkariMp3Player();
		break;
		case 'application/x-pando':
			return new PokkariPandoPlayer();
		break;
		case 'application/pando':
			return new PokkariPandoPlayer();
		break;
		default:
			return new PokkariPlayer();
		break;
        }

	return new PokkariPlayer();
}

function PokkariWindowsPlayer(params) {
	this.controlsHeight = document.all ? 26 : 40;
}

PokkariWindowsPlayer.prototype = new PokkariPlayer();
PokkariWindowsPlayer.prototype.constructor = PokkariWindowsPlayer;
PokkariWindowsPlayer.prototype.superclass = PokkariPlayer;

PokkariWindowsPlayer.prototype.getPrimaryMediaUrl = function() {

	if (window.navigator.platform == "Win32" &&
		(this.isAdProvidedBy("postroll_postroller") ||
		this.getPrerollAnimationUrl() ||
		this.getPostrollAnimationUrl()))
	{

		var filename = /\/file\/get\/(.*?)\?/;
		var results = filename.exec(PokkariPlayer.prototype.getPrimaryMediaUrl.apply(this,[]));
		var url = new Url(this.getPermalinkUrl());
		url.setQueryParam("skin","asx");
		url.setQueryParam("filename",results[1]);
		url.setQueryParam("preurl",this.getPrerollAnimationUrl());
		url.setQueryParam("posturl",this.getPostrollAnimationUrl());
		return url.getUrl();
	}
	else {
		return PokkariPlayer.prototype.getPrimaryMediaUrl.apply(this,[]);
	}
}

PokkariWindowsPlayer.prototype.getHtml = function() {
		if(!this.getPrimaryMediaUrl()) {
		throw("Cannot render without primary media URL");
	}
	if(!this.getPlayerTarget()) {
		throw("Cannot render without player target");
	}

	var autoPlay = (this.getAutoPlay()) ? 'true' : 'false';
	var objectId = this.getObjectId();
	var embedId = this.getEmbedId();

	var html = '<object id="' + objectId + '" width="' + this.getPlayerWidth() + '" height="' + this.getPlayerHeight() + '" classid="CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95" codebase="http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701" standby="Loading Microsoft Windows Media Player components...", type="application/x-oleobject">';


	html += '<param name="fileName" value="' + this.getPrimaryMediaUrl() + '">';
	html += '<param name="animationStart" value="true">';

	if (typeof(this.startTime) != "undefined" && this.startTime) {
		html += '<param name="currentPosition" value="'+this.startTime+'">';
		autoPlay = true;
	}

	html += '<param name="AutoStart" value="' + autoPlay + '">';
	html += '<param name="showControls" value="true">';
	html += '<param name="transparentatStart" value="false">';
	html += '<param name="loop" value="false">';

	html += '<embed type="application/x-mplayer2" pluginspage="http://www.microsoft.com/Windows/MediaPlayer/" id="' + embedId + '" name="'+ embedId + '" displaysize="4" autosize="-1" bgcolor="darkblue" showcontrols="true" showtracker="-1" showdisplay="0" showstatusbar="-1" videoborder3d="-1" width="' + this.getPlayerWidth() + '" height="' + this.getPlayerHeight() + '" src="' + this.getPrimaryMediaUrl() + '" autostart="' + autoPlay + '" designtimesp="5311" loop="false"';
	if (typeof(this.startTime) != "undefined" && this.startTime) {
		html += ' currentPosition="'+this.startTime+'"';
	}

	html += '></embed>';
	html += '</object>';

	return html;
}

/*
PokkariWindowsPlayer.prototype.render = function() {
	var html = this.getHtml();

	this.getPlayerTarget().style.width = this.getPlayerWidth() + "px";
	this.getPlayerTarget().style.height = this.getPlayerHeight() + "px";

	this.getPlayerTarget().innerHTML = html;

	this.onRendered();
}
*/

PokkariWindowsPlayer.prototype.setTime = function(time) {
	var s = this.ensureSeconds(time);
	var player = this.getPlayer();

	if (typeof(player) != "undefined") {
		if (typeof(player.object) != "undefined")
			player.object.CurrentPosition = s;
		else if (typeof(player.controls) != "undefined")
			player.controls.currentPosition = s;
	}
}

PokkariWindowsPlayer.prototype.getTime = function() {
	var player = this.getPlayer();

	if (typeof(player) != "undefined") {
		if (typeof(player.object) != "undefined")
			return player.object.CurrentPosition;
		else if (typeof(player.controls) != "undefined")
			return player.controls.currentPosition;
	}

	return null;
}

PokkariWindowsPlayer.prototype.getDuration = function() {
	var player = this.getPlayer();

	if (typeof(player) != "undefined") {
		if (typeof(player.currentMedia) != "undefined")
			return player.currentMedia.duration;
		else if (typeof(player.object) != "undefined")
			return player.object.Duration;
	}

	return null;
}

PokkariWindowsPlayer.prototype.getStatus = function() {
	// TODO FIXME Convert status
	//Value 	State 	Description
	//0 	Undefined 	Windows Media Player is in an undefined state.
	//1 	Stopped 	Playback of the current media item is stopped.
	//2 	Paused 	Playback of the current media item is paused. When a media item is paused, resuming playback begins from the same location.
	//3 	Playing 	The current media item is playing.
	//4 	ScanForward 	The current media item is fast forwarding.
	//5 	ScanReverse 	The current media item is fast rewinding.
	//6 	Buffering 	The current media item is getting additional data from the server.
	//7 	Waiting 	Connection is established, but the server is not sending data. Waiting for session to begin.
	//8 	MediaEnded 	Media item has completed playback.
	//9 	Transitioning 	Preparing new media item.
	//10 	Ready 	Ready to begin playing.
	//11 	Reconnecting
	var player = this.getPlayer();

	if (typeof(player) != "undefined") {
		var state;

		if (typeof(player.object) != "undefined")
			state = player.object.PlayState;
		else if (typeof(player.playState) != "undefined")
			state = player.playState;

		if (state == 1 || state == 0)
			return "Paused";
		else if (state == 2)
			return "Playing";
		else if (state == 5)
			return "Loading";
		else if (state == 6)
			return "Waiting";
		else if (state == 7)
			return "Played";
		else if (state == 9)
			return "Complete";
		else
			return "Undefined";
	}
	else {
		return "Unsupported";
	}
}

PokkariWindowsPlayer.prototype.setStatus = function(value) {
	var player = this.getPlayer();

	if (typeof(player) != "undefined") {
		try {
			if (value == "Playing") {
				if (typeof(player.play) != "undefined") {
					player.play();
					return value;
				}
				if (typeof(player.controls) != "undefined" &&
					typeof(player.controls.play) != "undefined"
				) {
					player.controls.play();
					return value;
				}
				if (typeof(player.object) != "undefined" &&
					typeof(player.object.controls) != "undefined" &&
					typeof(player.object.controls.play) != "undefined"
				) {
					player.object.controls.play();
					return value;
				}
			}
			else if (value == "Paused") {
				if (typeof(player.pause) != "undefined") {
					player.pause();
					return value;
				}
				if (typeof(player.controls) != "undefined" &&
					typeof(player.controls.pause) != "undefined"
				) {
					player.controls.pause();
					return value;
				}
				if (typeof(player.object) != "undefined" &&
					typeof(player.object.controls) != "undefined" &&
					typeof(player.object.controls.pause) != "undefined"
				) {
					player.object.controls.pause();
					return value;
				}
			}
		}
		catch (err) {}
	}

	return null;
}

function PokkariQuicktimePlayer(params) {
	// Backwards Compatibility
	if (this.MAX_WIDTH)
		PokkariPlayerOptions.maxWidth=this.MAX_WIDTH;

	this.controlsHeight = 20;
}

PokkariQuicktimePlayer.prototype = new PokkariPlayer();
PokkariQuicktimePlayer.prototype.constructor = PokkariQuicktimePlayer;
PokkariQuicktimePlayer.prototype.superclass = PokkariPlayer;

PokkariQuicktimePlayer.prototype.getTime = function() {
	var player = this.getPlayer();

	return player.GetTime() / player.GetTimeScale();
}

PokkariQuicktimePlayer.prototype.setTime = function(time) {
	var player = this.getPlayer();

	time = time * player.GetTimeScale();

	player.SetTime(time);
}

PokkariQuicktimePlayer.prototype.getDuration = function() {
	var player = this.getPlayer();

	return player.GetDuration() / player.GetTimeScale();
}

PokkariQuicktimePlayer.prototype.getStatus = function() {
	var player = this.getPlayer();

	if (player && typeof(player.GetPluginStatus) != "undefined") {
		var status = player.GetPluginStatus();

		if (status == "Complete" || status == "Completed" || status == "Playable") {

			var time = player.GetTime();
			var totalTime = player.GetDuration();
			var rate = player.GetRate();

			if (time >= totalTime)
				return "Played";
			else if (rate > 0)
				return "Playing";
			else if (rate == 0)
				return "Paused";
			else
				return status;
		}
		else
			return status;
	}

	return "Undefined";
}

PokkariQuicktimePlayer.prototype.setStatus = function(value) {
	var player = this.getPlayer();

	if (player) {
		if (value == "Playing" && typeof(player.Play) != "undefined") {
			player.Play();
			return value;
		}
		else if (value == "Paused" && typeof(player.Stop) != "undefined") {
			player.Stop();
			return value;
		}
	}

	return null;
}

PokkariQuicktimePlayer.prototype.getHtml = function() {
	if(!this.getPrimaryMediaUrl()) {
		throw("Cannot render without primary media URL");
	}
	if(!this.getPlayerTarget()) {
		throw("Cannot render without player target");
	}

	var autoPlay = (this.getAutoPlay()) ? 'true' : 'false';
	var objectId = this.getObjectId();
	var embedId = this.getEmbedId();

	var html = '<object id="' + objectId + '" classid="clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B" width="' + this.getPlayerWidth() +
		'" height="' + this.getPlayerHeight() + '" codebase="http://www.apple.com/qtactivex/qtplugin.cab">';

	html += '<param name="src" value="' + this.getPrimaryMediaUrl() + '">';
	html += '<param name="autoplay" value="' + autoPlay + '">';
	html += '<param name="controller" value="true">';
	html += '<param name="uimode" value="full">';
	html += '<param name="scale" value="aspect">';

	html += '<embed name="' + embedId + '" src="' + this.getPrimaryMediaUrl() + '" autoplay="' + autoPlay +
		'" controller="true" width="' + this.getPlayerWidth() + '" height="' + this.getPlayerHeight() +
		'" scale="aspect" EnableJavaScript="true" type="video/quicktime"></embed>';

	html += '</object>';

	return html;
}

/*
PokkariQuicktimePlayer.prototype.render = function() {
	var html = this.getHtml();

	this.getPlayerTarget().style.width = this.getPlayerWidth() + "px";
	this.getPlayerTarget().style.height = this.getPlayerHeight() + "px";

	this.getPlayerTarget().innerHTML = html;

	this.onRendered();
}
*/

function PokkariImagePlayer(params) {
}

PokkariImagePlayer.prototype = new PokkariPlayer();
PokkariImagePlayer.prototype.constructor = PokkariImagePlayer;
PokkariImagePlayer.prototype.superclass = PokkariPlayer;

PokkariImagePlayer.prototype.getHtml = function() {
	var html = '<img src="' + this.getPrimaryMediaUrl() + '" width="' + this.getWidth() + '" height="' + this.getHeight() + '" />';

	return html;
}

PokkariImagePlayer.prototype.render = function() {
	if (!this.duration) {
		this.duration = 15;
	}

	PokkariPlayer.prototype.render.apply(this);
}

//PokkariImagePlayer.prototype.getStatus = function() {
//	return "Played";
//}

function PokkariFlashPlayer(params) {
	// Backwards Compatibility
	if (this.MAX_WIDTH)
		PokkariPlayerOptions.maxWidth=this.MAX_WIDTH;
}

PokkariFlashPlayer.prototype = new PokkariPlayer();
PokkariFlashPlayer.prototype.constructor = PokkariFlashPlayer;
PokkariFlashPlayer.prototype.superclass = PokkariPlayer;

PokkariFlashPlayer.prototype.getPlayerHeight = function() {
	var height = PokkariPlayer.prototype.getPlayerHeight.apply(this);

	return parseInt(height)+20;
}

PokkariFlashPlayer.prototype.getHtml = function() {
	var autoPlay = (this.getAutoPlay()) ? '1' : '0';
	var query = "file=" + escape(this.getPrimaryMediaUrl());

	if (this.getAutoPlay()) {
		query += "&autoStart=1";
	}

    if (this.getUsersId() == 12877) {
		if (this.getPostsId() >= 123933 && this.getPostsId() <= 126990) {
			query += "&trailerMovie=http://www.blip.tv/scripts/flash/starrring.swf";
		}
		else if (this.getPostsId() >= 131118 && this.getPostsId() <= 132751) {
			query += "&trailerMovie=http://www.blip.tv/scripts/flash/starrring-video1.swf";
		}
		else if (this.getPostsId() == 134504) {
			query += "&trailerMovie=http://www.blip.tv/scripts/flash/starrring-video2.swf";
		}
		else if (this.getPostsId() > 134504 && this.getPostsId() <= 196949) {
			query += "&trailerMovie=http://www.blip.tv/scripts/flash/starrring-paltalk-slate.swf";
		}
	}
	else if (this.isAdProvidedBy("postroll_blip")) {
		query += "&trailerMovie=" + escape(this.getBaristaUrl("post","flv","blip","url") + "&ext=.swf");

		if (this.getUsersId() == 1 || this.getUsersId() == 48245) {
			query += "&trailerResize=0";
		}
	}
	else if (this.isAdProvidedBy("postroll_author")) {
		query += "&trailerMovie=" + escape(this.getBaristaUrl("post","flv","author","post"));
	}
	else if (this.isAdProvidedBy("postroll_postroller")) {
		query += "&trailerMovie=http://1048.btrll.com/ad/12060%3Fvid%3D" + this.getPostsId() + "%26sid%3D" + this.getUsersId() +
			"%26kw%3D" + escape(this.getTopics()) + "%26type%3D.swf";
	}
	else if (this.isAdProvidedBy("postroll_immense")) {
		query += "&adProvider=immense";
	}
	else if (this.isAdProvidedBy("postroll_google")) {
		query += "&adProvider=google&guid=" + this.getPostsId();
	}
	else if (this.getPostrollAnimationUrl()) {
		query += "&trailerMovie=" + this.getPostrollAnimationUrl();
	}

	if (this.getPrerollAnimationUrl()) {
		query += "&thumbNail=" + this.getPrerollAnimationUrl();
	}
	if (this.getUsersId()) {
		query += "&userId=" + escape(this.getUsersId());
	}
	if (this.getUsersLogin()) {
		query += "&userLogin=" + escape(this.getUsersLogin());
	}
	if(this.getPostsTitle()) {
		query += "&postsTitle=" + escape(this.getPostsTitle());
	}
	if(this.getPostsId()) {
		query += "&postsId=" + escape(this.getPostsId());
	}
	if(this.getTopics()) {
		query += "&topics=" + escape(this.getTopics());
	}
	if (this.getThumbnail()) {
		query += "&thumbNail=" + escape(this.getThumbnail());
	}

	if (document.all) {
		query += "&cacheBuster=" + Math.floor(Math.random() * 10000);
	}

	var objectId = this.getObjectId();
	var embedId = this.getEmbedId();

	var html = '<object id="' + objectId + '" type="application/x-shockwave-flash" width="' + this.getPlayerWidth() + '" height="' + this.getPlayerHeight() + '"';

	if (this.getWmode()) {
		html += ' wmode="' + this.getWmode() + '"';
	}

	html += ' data="' + this.getSiteUrl() + '/scripts/flash/blipplayer.swf?' + query + '">';
	html += '<param name="movie" value="' + this.getSiteUrl() +
		'/scripts/flash/blipplayer.swf?' + query + '">';
	html += '<param name="flashvars" value="' + query + '" />';
	html += '<param name="allowScriptAccess" value="always" />';

	if (this.getWmode()) {
		html += '<param name="wmode" value="' + this.getWmode() + '" />';
	}
	html += '</object>';

	return html;
}

PokkariFlashPlayer.prototype.render = function() {

	var hasProductInstall = DetectFlashVer(6, 0, 65);
	var hasRequestedVersion = DetectFlashVer(8, 0, 0);

//	if(hasProductInstall && hasRequestedVersion) {
	if (true) {
		PokkariPlayer.prototype.render.apply(this);
	} 
	else {
		var html = '<div class="flash_error_msg">'
		+ '<div class="user_info_title">Ooops</div>'
		+ '<p>If you\'d like to see this video you\'ll need to install <a href="http://www.adobe.com/go/getflashplayer/">Macromedia Flash Player 8</a> (please note that we require Flash 8, and an installation of an earlier version like Flash 7 will not work).</p>'
		+ '<a href="http://www.adobe.com/go/getflashplayer"><img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" /></a>'
		+ '<p>If you feel you\'ve reached this message in error, please <a href="mailto:support@blip.tv">let us know</a>.</p>'
		+ '</div></div>';
		if (PokkariPlayerOptions.useDocumentWrite) {
			document.write(html);
		}
		else {
			this.getPlayerTarget().innerHTML = html;
		}
	}
}

PokkariFlashPlayer.prototype.getTime = function() {
	var player = this.getPlayer();

	try {
		if (player && typeof(player.GetVariable) != "undefined") {
			return player.GetVariable("_root.videoCurrentTime");
		}
	}
	catch (err) {}

	return null;
}

PokkariFlashPlayer.prototype.setTime = function(value) {
	var player = this.getPlayer();

	try {
		if (player && typeof(player.SetVariable) != "undefined") {
			player.SetVariable("_root.videoSetCurrentTime",value);
		}
	}
	catch (err) {}
}

PokkariFlashPlayer.prototype.getDuration = function(value) {
	var player = this.getPlayer();

	try {
		if (player && typeof(player.GetVariable) != "undefined") {
			return player.GetVariable("_root.videoTotalTime");
		}
	}
	catch (err) {}

	return null;
}

PokkariFlashPlayer.prototype.getStatus = function(value) {
	var player = this.getPlayer();

	try {
		if (player && typeof(player.GetVariable) != "undefined") {
			var status = player.GetVariable("_root.currentVideoStatus");

			return status || "Undefined";
		}
	}
	catch (err) {}

	return "Undefined";
}

PokkariFlashPlayer.prototype.setStatus = function(value) {
	var player = this.getPlayer();

	try {
		if (player && typeof(player.SetVariable) != "undefined") {
			player.SetVariable("_root.setCurrentVideoStatus",value);
			return value;
		}
	}
	catch (err) {}

	return null;
}

function PokkariTheoraPlayer(params) {
	this.controlsHeight = 20;
}

PokkariTheoraPlayer.prototype = new PokkariPlayer();
PokkariTheoraPlayer.prototype.constructor = PokkariTheoraPlayer;
PokkariTheoraPlayer.prototype.superclass = PokkariPlayer;  // This isnt necessary is it?

PokkariTheoraPlayer.prototype.getHtml = function() {
		var url = this.getPrimaryMediaUrl();
	var width = this.getWidth();
	var height = this.getHeight();

	var html =  '<object classid="clsid:CAFEEFAC-0014-0002-0000-ABCDEFFEDCBA"\n' +
		'width="' + width + '" height="' + height + '"\n' +
	    'codebase="http://java.sun.com/products/plugin/autodl/jinstall-1_4_2-windows-i586.cab#Version=1,4,2,0">\n' +
		'<param name="code" value="com.fluendo.player.Cortado.class" />\n' +
		'<param name="codebase" value="/cortado.jar" />\n' +
		'<param name="archive" value="/cortado.jar" />\n' +
	    '<param name="type" value="application/x-java-applet;jpi-version=1.4.2">\n' +
	    '<param name="scriptable" value="true">\n' +
		'<param name="url" value="' + url + '" />\n' +
		'<param name="local" value="false" />\n' +
		'<param name="keepaspect" value="true" />\n' +
		'<comment>\n' +
		'<APPLET code="com.fluendo.player.Cortado.class"\n' +
		'codebase="/cortado.jar"\n' +
		'archive="/cortado.jar"\n' +
        'width="' + width + '" height="' + height + '">\n' +
  		'<PARAM name="url" value="' + url + '"/>\n' +
	  	'<PARAM name="local" value="false"/>\n' +
	  	'<PARAM name="keepaspect" value="true"/>\n' +
		'</APPLET>\n' +
		'</comment>\n' +
		'</object>\n';

	return html;
}
/*
PokkariTheoraPlayer.prototype.render = function() {
	var html = this.getHtml();

	this.getPlayerTarget().innerHTML = html;

	this.onRendered();
}
*/

function PokkariMp3Player(params) {
}

PokkariMp3Player.prototype = new PokkariPlayer();
PokkariMp3Player.prototype.constructor = PokkariMp3Player;
PokkariMp3Player.prototype.superclass = PokkariPlayer;

PokkariMp3Player.prototype.getHtml = function() {
	var autoPlay = (this.getAutoPlay()) ? 'true' : 'false';
	var query = "song_url=" + escape(this.getPrimaryMediaUrl()) + "&autoload=" + autoPlay + "&song_title=" + escape(this.getPostsTitle());

	var objectId = this.getObjectId();
	var embedId = this.getEmbedId();

	var html = '<object id="' + objectId + '" type="application/x-shockwave-flash" width="' + this.getPlayerWidth() + '" height="' + this.getPlayerHeight() + '" wmode="transparent" data="' + this.getSiteUrl() + '/scripts/flash/blipmp3player.swf?' + query + '">';
	html += '<param name="movie" value="' + this.getSiteUrl() + '/scripts/flash/blipmp3player.swf?' + query + '">';
	html += '<param name="flashvars" value="' + query + '" />';
	html += '<param name="wmode" value="transparent" />';
	html += '</object>';

	return html;
}

PokkariMp3Player.prototype.render = function() {
	var html = this.getHtml();

	if (PokkariPlayerOptions.useDocumentWrite) {
		document.write(html);
	}
	else {
		this.getPlayerTarget().innerHTML = html;
		this.onRendered();
	}

}

function PokkariShowPlayer() {
	this.controlsHeight = 30;
}
PokkariShowPlayer.prototype = new PokkariPlayer();
PokkariShowPlayer.prototype.constructor = PokkariShowPlayer;
PokkariShowPlayer.prototype.superclass = PokkariPlayer;

PokkariShowPlayer.prototype.render = function() {
	PokkariPlayer.prototype.render.apply(this,[]);

	if (typeof(window.video_player_object) == "undefined") {
		// The showplayer erroneously refers to the player like this..
		window.video_player_object = this.getPlayer();
	}

//	if (this.isHtml5Player) {
//		var objectId = this.getEmbedId();
//		var showPlayerUrl = (PokkariPlayerOptions.showPlayerOptions && PokkariPlayerOptions.showPlayerOptions.playerUrl) ||
//			(this.getSiteUrl() + "/scripts/flash/showplayer.swf");
//		var playerUrl = showPlayerUrl.replace("/scripts/flash/showplayer.swf","/scripts/shoggplayer.html");
//		var playbackUrl = this.getPlaybackUrl(playerUrl);
//		var url = playbackUrl.getUrl();
//
//		if (PokkariPlayerOptions.useDocumentWrite) {
//			window.addEventListener("load",function() { var player = new BLIP.ShoggPlayer.Player({ 'parent':objectId, 'options':url }); },true);
//		}
//		else {
//			var player = new BLIP.ShoggPlayer.Player({ 'parent':objectId, 'options':url });
//		}
//	}
}

PokkariShowPlayer.prototype.getFileUrl = function() {
	var file = this.getSiteUrl() + "/rss/flash/" + this.getPostsId();

	var media = this.getPrimaryMediaUrl();

	var result = Url.ReplaceQuery(file,Url.GetQuery(media));

	return result;
}

PokkariShowPlayer.prototype.getPlaybackUrl = function(playerUrl) {
	var url = new Url(playerUrl);

	url.setQueryParam("file", this.getFileUrl());
	url.setQueryParam("enablejs","true");
	url.setQueryParam("showplayerpath",playerUrl);
	url.setQueryParam("onsite", "true");

	if (this.getAutoPlay()) {
		url.setQueryParam("autostart","true");
	}
	else if (this.getThumbnail()) {
		url.setQueryParam("thumb",this.getThumbnail());
	}

	if (this.getUsersFeedUrl()) {
		url.setQueryParam("feedurl",this.getUsersFeedUrl());
	}

	this.includeOptions(url,PokkariPlayerOptions.showPlayerOptions);

	if (typeof(BLIP) != "undefined" && BLIP.Shenanigans) {
		url.setQueryParam("noAds","true");
		url.setQueryParam("noAward","true");
	}

	return url;
}

PokkariShowPlayer.prototype.getHtml = function() {
	// Save these for later so we can use them to drive the template.
	this.couldPlayHtml5 = this.canPlayHtml5();
	this.isHtml5Player = this.isHtml5Enabled() && this.couldPlayHtml5;

	return this.isHtml5Player ? this.getHtml5Html() : this.getFlashHtml();
}

PokkariShowPlayer.prototype.getFlashHtml = function() {
	var playerUrl = (PokkariPlayerOptions.showPlayerOptions && PokkariPlayerOptions.showPlayerOptions.playerUrl) ||
		(this.getSiteUrl() + "/scripts/flash/stratos.swf");

	var url = this.getPlaybackUrl(playerUrl);
	var urlString = url.getUrl();

	if (PokkariPlayerOptions.useHashTag) {
		urlString = urlString.replace('\?', '#');
	}

	var width = this.getPlayerWidth();
	var height = this.getPlayerHeight();
	var objectId = this.getObjectId();
	var embedId = this.getEmbedId();
	var wmode = "opaque";

	if (PokkariPlayerOptions.useScanScoutShim) {
		wmode = (navigator.userAgent.indexOf("Safari") > -1 &&
			this.isAdProvidedBy("adjacent_scanscout") &&
			this.hasScanScoutHtml) ? "opaque" : "window";
	}

	var html='\n<object id="' + objectId +'" type="application/x-shockwave-flash" ' +
		'width="' + width + '" ' +
		'height="' + height + '" ' +
		'classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" ' +
		'codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" ' +
		'allowfullscreen="true" allowscriptaccess="always">\n' +
		'\t<param name="allowfullscreen" value="true" />\n'+
		'\t<param name="allowscriptaccess" value="always" />\n'+
		'\t<param name="wmode" value="'+wmode+'" />\n' +
		'\t<param name="movie" value="' + urlString + '" />\n' +
		'\t<param name="quality" value="best" />\n' +
		'\t<embed width="' + width + '" height="' + height + '"\n' +
		'\t\ttype="application/x-shockwave-flash" wmode="'+wmode+'"\n' +
		'\t\tallowscriptaccess="always" allowfullscreen="true"\n' +
		'\t\tpluginspage="http://www.macromedia.com/go/getflashplayer"\n' +
		'\t\tsrc="' + urlString + '" id="' + embedId +'" />' +
		'</object>\n';

	if (typeof(BLIP) != "undefined" && BLIP.Shenanigans) {
		return "<div></div>";
	}

	return html;
}

PokkariShowPlayer.prototype.getTime = function() {
	return PokkariShowPlayer.currentTime || 0;
}

PokkariShowPlayer.prototype.getStatus = function() {
	switch (PokkariShowPlayer.currentState) {
		case 1:
			return "Complete";
		case 3:
			return "Complete";
		case 2:
			return "Playing";
		case 0:
			return "Paused";
		default:
			return "Playing";
	}
}

PokkariShowPlayer.prototype.setStatus = function(value) {
	var player = this.getPlayer();

	if (value == "Playing") {
		player.sendEvent("play");
	}
	else if (value == "Paused") {
		player.sendEvent("pause");
	}
}

PokkariShowPlayer.prototype.ss_pause = function() {
	// We're outside of context here.   Use ss' context.
	var self = ss_videoPlayer;
	self.pause();

	// Need to give ss time to build and display EAU
	if (PokkariPlayerOptions.useScanScoutShim) {
		var context = self.storeContext();
		window.setTimeout("PokkariPlayer.retreiveContext('"+context+"').hidePlayerForScanScout();",100);
	}
}

PokkariShowPlayer.prototype.ss_play = function() {
	// We're outside of context here.   Use ss' context.
	var self = ss_videoPlayer;
	self.play();

	if (PokkariPlayerOptions.useScanScoutShim)
		self.showPlayerForScanScout();
}

PokkariShowPlayer.prototype.hidePlayerForScanScout = function() {
	var eau = document.getElementById("EAU");
	var player = this.getPlayer();

	if (eau && navigator.userAgent.indexOf("Safari") == -1) {
			player.style.visibility = "hidden";
	}
}

PokkariShowPlayer.prototype.showPlayerForScanScout = function() {
	var player = this.getPlayer();

	if (navigator.userAgent.indexOf("Safari") == -1) {
		player.style.visibility = "visible";
	}
}

PokkariShowPlayer.prototype.includeOptions = function(url,options) {
	if (typeof(options) == "string") {
		options = Url.ParseQuery(options);
	}

	if (typeof(options) == "object") {
		for (var i in options) {
			if (/^string|number|boolean$/.test(typeof(options[i]))) {
				url.setQueryParam(i,options[i]);
			}
		}
	}
}

PokkariShowPlayer.prototype.isHtml5Enabled = function() {
	var result = PokkariPlayerOptions.showPlayerOptions.enableHtml5Player && 
		/enableHtml5Player=true/.test(document.cookie);

	return result;
}

PokkariShowPlayer.prototype.canPlayHtml5 = function() {
	var v = document.createElement("video");
	if (v && v.canPlayType && this.availableMimeTypes) {
		for (var i=0; i<this.availableMimeTypes.length; i++) {
			if (v.canPlayType(this.availableMimeTypes[i])) {
				return true;
			}
		}
	}

	return false;
}

PokkariShowPlayer.canPlayType = function(type) {
	if (/\bvideo\/(?:flv|x-flv)\b/.test(type)) {
		return true;
	}

	return false;
}

PokkariShowPlayer.prototype.getHtml5Html = function() {
	var showPlayerUrl = (PokkariPlayerOptions.showPlayerOptions && PokkariPlayerOptions.showPlayerOptions.playerUrl) ||
		(this.getSiteUrl() + "/scripts/flash/showplayer.swf");
	var playerUrl = showPlayerUrl.replace("/scripts/flash/showplayer.swf","/scripts/shoggplayer.html");
	var playbackUrl = this.getPlaybackUrl(playerUrl);

	var width = this.getPlayerWidth();
	var height = this.getPlayerHeight();
	var objectId = this.getEmbedId();
//	var html = '\n<iframe id="' + objectId + '"\n' +
//		'\tsrc="' + playbackUrl.getUrl() + '"\n' +
//		'\twidth="' + width + '"\n' +
//		'\theight="' + height + '"\n' +
//		'\tframeborder="0"></iframe>\n';

	var html = '\n<div id="' + objectId + '" style="width:' + width + 'px; height:' + height + 'px"></div>\n' +
		'\t<scr'+'ipt src="/scripts/ShoggPlayer-min.js?version=HEYJUDEYJUDE" type="text/javascript"></scr'+'ipt>\n' +
		'\t<scr'+'ipt>(function() { var player = new BLIP.ShoggPlayer.Player({ parent:"' + objectId + '", options:"' + playbackUrl.getUrl() + '" }); })();</scr'+'ipt>\n';

	return html;
}

function getUpdate(type, arg1, arg2) {
	switch (type) {
		case "time":
			PokkariShowPlayer.currentTime = arg1;
		break;
		case "state":
			PokkariShowPlayer.currentState = arg1;
		break;
	}
}

function PokkariPandoPlayer() {
}

PokkariPandoPlayer.prototype = new PokkariPlayer();
PokkariPandoPlayer.prototype.constructor = PokkariPandoPlayer;
PokkariPandoPlayer.prototype.superclass = PokkariPlayer;

PokkariPandoPlayer.prototype.getHtml = function() {
	var html = "\n<div class='Pando' style='border: 1px solid #ddd; padding: 30px;'><div class='PandoLogo' style='text-align:center; margin-bottom:25px;'>" +
		"<a href='http://www.pando.com/'><img src='" + this.getSiteUrl() + "/skin/blipnew/partners/pando.png' border='0' /></a>" +
		"</div>\n<div class='PandoText' style='width:450px; margin:auto'>" + 
		"<div class='PandoButton' style='float:left; margin-right: 10px'><a href='" + this.getPrimaryMediaUrl() + "'";
		
	if (!this.hasPando()) {
		html += " target='_blank'";
	}

	html += "><img src='http://rss.pando.com/themes/rssvideo/pando_dl_button2.png' border='0' /></a></div>\n" +
		"This video is available via <a href='http://www.pando.com/'>Pando</a>.  Use the button on the " +
		"left begin your download.</div>\n<div class='Clear'> </div>\n</div>\n";

	return html;
}

PokkariPandoPlayer.prototype.hasPando = function() {
	return PokkariPandoPlayer.hasPando && true;
}

PokkariPandoPlayer.prototype.setPandoUrl = function(url) {
	this.pandoUrl = url;
}

PokkariPandoPlayer.prototype.getPrimaryMediaUrl = function() {
	var url = this.pandoUrl || PokkariPlayer.prototype.getPrimaryMediaUrl.apply(this,[]);
	return PokkariPandoPlayer.getDownloadUrl(url);
}

PokkariPandoPlayer.initialize = function(callback) {
	if (typeof(PokkariPandoPlayer.hasPando) == "undefined") {
		if (/hasPando=/.test(document.cookie)) {
			PokkariPandoPlayer.hasPando = document.cookie.replace(/.*hasPando=([^;]+).*/,"$1");
		}
		else {
			if (callback) {
				PokkariPandoPlayer.initializeCallbackCallback = callback;
			}

			document.write("<script type='text/javascript' src='http://cache.pando.com/soapservices/PandoAPI.js'></script>");

			// I know this seems weird, since we're already in javascript, but we want to make sure these things happen in order...
			document.write("<script>PandoAPI.hasPando(PokkariPandoPlayer.initializeCallback);</script>");

			// Set a 3 second backup timer so the callback for sure fires.
			PokkariPandoPlayer.backupTimer = window.setTimeout("PokkariPandoPlayer.initializeCallback(false);",3000);
		}
	}
}

PokkariPandoPlayer.initializeCallback = function(hasPando) {
	if (PokkariPandoPlayer.backupTimer) {
		window.clearTimeout(PokkariPandoPlayer.backupTimer);
	}

	PokkariPandoPlayer.hasPando = hasPando && true;

	var date = new Date();
	date.setTime(date.getTime()+(365*24*60*60*1000));
	document.cookie = "hasPando=" + PokkariPandoPlayer.hasPando + "; domain=.blip.tv; path=/; expires=" + date.toGMTString();

	if (PokkariPandoPlayer.initializeCallbackCallback) {
		PokkariPandoPlayer.initializeCallbackCallback();
	}
}

PokkariPandoPlayer.getDownloadUrl = function(url) {
	if (PokkariPandoPlayer.hasPando) {
		return PokkariPandoPlayer.getPandoDownloadUrl(url);
	}
	else {
		return PokkariPandoPlayer.getPandoInstallDownloadUrl(url);
	}
}

PokkariPandoPlayer.getPandoDownloadUrl = function(url) {
	return "pando:download?" + url;
}

PokkariPandoPlayer.getPandoInstallDownloadUrl = function(url) {
	if (/^http:\/\/cache.pando.com\//.test(url)) {
		var u = new Url(url);
		var pkg = u.getQueryParam('id');
		var key = u.getQueryParam('key');

		return "http://www.pando.com/link/preinstall?package=" + pkg + "&key=" + key + "&referer=" + window.location.href;
	}
	else {
		return "http://www.pando.com/download?packageURL=" + escape(url);
	}
}

PokkariPandoPlayer.subscribe = function(url,title) {
	window.location.href = PokkariPandoPlayer.getSubscribeUrl(url,title);
}

PokkariPandoPlayer.getSubscribeUrl = function(url,title) {
	if (PokkariPandoPlayer.hasPando) {
		return PokkariPandoPlayer.getPandoSubscribeUrl(url,title);
	}
	else {
		return PokkariPandoPlayer.getPandoInstallSubscribeUrl(url,title);
	}
}

PokkariPandoPlayer.getPandoSubscribeUrl = function(url,title) {
	return "pando:subscribe?" + url;
}

PokkariPandoPlayer.getPandoInstallSubscribeUrl = function(url,title) {
	return "http://www.pando.com/subscribe?rss=" + escape(url) + "&title=" + escape(title);
}

PokkariPandoPlayer.prototype.render = function() {
	if (typeof(PokkariPandoPlayer.hasPando) == "undefined") {
		var self = this;
		PokkariPandoPlayer.initialize(function() { self.render(); });
	}
	else {
		PokkariPlayer.prototype.render.apply(this,[]);
	}
}
