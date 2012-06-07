$(document).ready(function() {

    //	GENERAL BEHAVIORS
    if ($("#home").length > 0) {
        $("h1 a, #menu ul li:first-child a")
            .unbind("click")
            .bind("click", function(e) {
                e.preventDefault();
                $.scrollTo.window().queue([]).stop();
                $.scrollTo(0, 1200, {easing: "easeInOutQuart", offset: {top: 0}});
            });
    }

    $("#link_demos, .link_demos, #link_learn_more")
        .unbind("click")
        .bind("click", function(e) {
            e.preventDefault();
            $.scrollTo.window().queue([]).stop();
            $.scrollTo($(e.target).attr("href"), 1200, {easing: "easeInOutQuart", offset: {top: -60}});
        });

    $("#link_login")
        .unbind("click")
        .bind("click", function(e) {
            e.preventDefault();
            $("#login:not(:visible)")
                .fadeIn("slow");

        });
    $("#content_login .close")
        .unbind("click")
        .bind("click", function(e) {
            e.preventDefault();
            $("#login:visible")
                .fadeOut("fast");

        });

    //	SEARCH INPUT
    $(".search input:first")
        .each(function() {
            $(this)
                .data("default", $(this).val())
                .focus(function() {
                    if ($(this).val() == $(this).data("default")) {
                        $(this).val("");
                    }

                })
                .blur(function() {
                    $(this).val($.trim($(this).val()));
                    if ($(this).val() == $(this).data("default") || $(this).val() == "") {
                        $(this)
                            .val($(this).data("default"));
                    }
                });
        });

    $(".search form").submit(function(e) {
        var value = $(".search input:first").val();
        var pattern = /[ ,\n,\r]/g;
        if (value.replace(pattern, "").length > 0) {
            alert("SEARCHING: " + value);
        }
    });

    //	SCROLLER DEMO
    if ($("#content_slider").length > 0) {
        DemoScroller.init();
    }
    //	PRESENTZ PLAYER
    else if ($("#presentation").length > 0) {
        Controls.init();
    }


    $(window)
        .unbind("resize")
        .bind("resize", function(e) {
            if ($("#content_slider").length > 0) {
                DemoScroller.resize();
            }
        });

});
