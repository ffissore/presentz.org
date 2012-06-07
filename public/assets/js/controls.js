//GENERAL BEHAVIORS
var Controls = {

    totalChapters: 0,

    init: function() {
        var $this = this;
        $this.totalChapters = $(".chapter ", "#controls").length;
        $(".chapter", "#controls").each(function() {
            var instance = this;
            var percentW = 100 * ($(this).width() + 1) / ($("#controls").width() + 1);
            if (percentW < 0.25) {
                percentW = 0.25;
            }
            percentW += "%";

            $(this)
                .data("defaultPercentW", percentW)
                .unbind("mouseenter")
                .bind("mouseenter", function(e) {
                    var selectedChapterWidth = $("#controls").width() + 2 - ($this.totalChapters * 2);

                    $(".chapter", "#controls").not($(instance)).css("width", "2px");

                    $(instance).css("width", selectedChapterWidth + "px");
                    $(instance).find(".info").stop(true, true).delay(200).fadeIn(500);
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
