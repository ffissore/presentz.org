require("coffee-script");
require("./presentz.coffee");

setTimeout(function() {
    console.log(process.memoryUsage());
    global.gc();
    console.log(process.memoryUsage());
}, 10000);
