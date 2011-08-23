function Url(url) {
	this.setUrl(url);
}

Url.prototype.getUrl = function() {
	if (this.urlDirty) {
		this.updateUrl();
	}

	return this.url;
}

Url.prototype.setUrl = function(url) {
	this.url = url;
	this.query = this.parseQuery();
	this.urlDirty = false;
}

Url.prototype.getQuery = function() {
	return Url.GetQuery(this.url);
}

Url.prototype.parseQuery = function() {
	return Url.ParseQuery(this.getQuery());
}

Url.prototype.getQueryParam = function(name) {
	return this.query[name];
}

Url.prototype.setQueryParam = function(name,value) {
	if (value == '') {
		delete this.query[name];
	}
	else {
		this.query[name] = value;
	}
	this.urlDirty = true;
}

Url.prototype.removeQueryParam = function(name,value) {
	delete this.query[name];
	this.urlDirty = true;
}

Url.prototype.updateUrl = function() {
	this.url = Url.ReplaceQuery(this.url,Url.MakeQuery(this.query));
	this.urlDirty = false;
}

Url.prototype.getServer = function() {
    return Url.GetServer(this.url);
}

Url.GetQuery = function(url) {
	if (typeof(url) == "undefined" || !url)
		return null;

	var parts = url.split("?");
	var query = parts[1];
	if (query) {
		return query.split("#")[0];
	}

	return null;
}

Url.ParseQuery = function(query) {
	var result = new Object();

	if (typeof(query) != "undefined" && query) {
		// Split it into name/value pairs
		var crumbs = query.split(/[&;]/);
		for (var i=0; i<crumbs.length; i++) {
			// Split the name and value
			var crumb = crumbs[i].split("=");

			// No equals means that it's a keyword
			if (crumb.length < 2) {
				if (result.keywords) {
					result.keywords += ",";
				}
				else {
					result.keywords = "";
				}

				result.keywords += unescape(crumb[0]);
			}
			else {
				result[unescape(crumb[0])] = unescape(crumb[1]);
			}
		}
	}

	return result;
}

Url.MakeQuery = function(object) {
	if (typeof(object) == "undefined" || !object)
		return null;

	var result = "";

	for (var i in object) {
		if (typeof(object[i]) == "number" || typeof(object[i]) == "string" || typeof(object[i]) == "boolean") {
			if (result) {
				result += "&";
			}

			result += escape(i) + "=" + escape(object[i]);
		}
	}

	return result;
}

Url.ReplaceQuery = function(url,query) {
	var parts = url.split("?");
	var u = parts[0];
	var a;

	if (parts[1]) {
		parts = parts[1].split("#");
		a = parts[1];
	}

	if (query) {
		u += "?" + query;
	}

	if (a) {
		u += "#" + a;
	}

	return u;
}

Url.ChangeQueryParam = function(url,param,value)
{
	url = new Url(url);
	url.setQueryParam(param,value);

	return url.getUrl();
}

Url.ChangeLocationQueryParam = function(param,value)
{
	window.location.href = Url.ChangeQueryParam(window.location.href,param,value);
}

Url.GetServer = function(url)
{
    var server = url.replace(/.*?:\/\/([\w\.\-]+).*/,"$1");

    return server;
}
