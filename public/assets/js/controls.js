//GENERAL BEHAVIORS
var Controls = {

    totalChapters: 0,
    overScale: 3,

    init: function() {
        var $this = this;
        $this.totalChapters = $(".chapter ", "#controls").length;
        $(".chapter", "#controls").each(function() {
            var instance = this;
            var percentW = parseInt(Math.ceil(100 * $(this).width() / $("#controls").width())) + "%";

            $(this)
                .data("defaultPercentW", percentW)
                .unbind("mouseenter")
                .bind("mouseenter", function(e) {
                    $(".chapter", "#controls").not($(instance)).css("width", String($this.overScale) + "%");

                    $(instance).css("width", String(100 - ($this.totalChapters - 1) * $this.overScale) + "%");
                    $(instance).find(".info").stop(true, true).delay(200).fadeIn(800);
                })
                .unbind("mouseleave")
                .bind("mouseleave", function(e) {
                    $this.restoreOriginalWidth();
                });

        });

        $("#controls .chapter .info .comments a")
            .unbind("click")
            .bind("click", function(e) {
                alert("SHOW COMMENT FOR THIS SLIDE!");
            });

        $("#controls .chapter .info .title a")
            .unbind("click")
            .bind("click", function(e) {
                alert("GO TO THIS SLIDE!");
            });
    },

    restoreOriginalWidth: function() {
        $(".chapter", "#controls").each(function() {
            $(this).find(".info").stop(true, true).hide();
            $(this).css("width", $(this).data("defaultPercentW"));
        });

    },

    resize: function() {

    }
};
