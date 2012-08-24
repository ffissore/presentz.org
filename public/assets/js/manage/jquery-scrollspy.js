/*!
 * jQuery Scrollspy Plugin
 * Original author: @sxalexander
 * Crushed by @fridrik
 * Licensed under the MIT license
 */


;
(function($, window) {

    $.fn.extend({
        scrollspy: function(options) {

            var noop = function() {
            };

            var defaults = {
                buffer: 0,
                onEnter: options.onEnter ? options.onEnter : noop,
                onLeave: options.onLeave ? options.onLeave : noop
            };

            var options = $.extend({}, defaults, options);

            var $window = $(window);

            return this.each(function(idx, element) {

                var $element = $(element);
                var buffer = options.buffer;
                var inside = false;

                /* add listener to container */
                $window.bind('scroll', function(e) {
                    var xy = $window.scrollTop() + buffer;
                    var min = $element.position().top;
                    var max = min + $element.height();

                    /* if we have reached the minimum bound but are below the max ... */
                    if ((xy + $window.height()) >= min && xy <= max) {
                        if (!inside) {
                            /* trigger enter event */
                            inside = true;
                            options.onEnter(element, xy);
                        }
                    } else {
                        if (inside) {
                            /* trigger leave event */
                            inside = false;
                            options.onLeave(element, xy);
                        }
                    }
                });
            });
        }
    })
})(jQuery, window);
