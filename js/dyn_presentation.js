(function() {
  var qs = window.location.search.substring(1);
  var s = qs.split("&");
  for (i in s) {
    if (s[i].indexOf("p=") == 0 && s[i].length > 2) {
      var scriptUrl = s[i].substr(2);

      var script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = scriptUrl;

      var scripts = $("script");
      $(scripts[scripts.length - 1]).append(script);
    }
  }
})()