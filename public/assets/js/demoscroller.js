var DemoScroller = {
			
		displayItemNumber : 3,
		itemNumber : 0,
		content_slider_w : null,
		
		init : function()
		{
			this.resize();
			
			this.itemNumber =  $('#content_slider li.box4').length;
			if(this.itemNumber > this.displayItemNumber)
			{
				this.createNav();
			}	
		},
		
		createNav : function()
		{
			var $this = this;
			
			$('#slider').append("<div id='navigation_slider'></div>");		
			$('#navigation_slider').append("<ul></ul>");
			var numLi = Math.ceil(this.itemNumber / this.displayItemNumber);
			
			for(var i = 0; i <  numLi; i++)
			{
				var item = $("<li><a href='#/demopage/" + (i + 1) + "' rel='" + i +"'></a></li>");
				$('#navigation_slider ul').append(item);
			}
			
			var ulWidth = (parseInt($('#navigation_slider ul li:first').width()) +  parseInt( $('#navigation_slider ul li:first').css('marginLeft').replace('px','') * 2 )) * numLi;
			$('#navigation_slider ul').css('width', ulWidth + 'px');
			
			$('#navigation_slider ul li a')
				.unbind('click')
				.bind('click', function(e){
					e.preventDefault();
					$('#navigation_slider ul li a').removeClass();
					$(this).addClass('active');
					$this.moveScroll(parseInt( $(this).attr('rel') ));
				});
			
			
			$('a', '#navigation_slider ul li:first').trigger('click');
		},

		moveScroll : function(value)
		{
			$('#content_slider').stop(true, false).animate({'left': - (value * $('#slider').width())}, 1200, 'easeInOutQuart');
		},
		
		resize : function()
		{
			if($('#content_slider').length > 0)
			{	
				this.content_slider_w = $('#content_slider li.box4').length * parseInt(parseInt($('.box4').css('width').replace('px','')) + (parseInt($('.box4').css('margin-left').replace('px','')) * 2));
				$('#content_slider').css('width', this.content_slider_w);
				
				$('#navigation_slider ul li a.active').click();
			}
		}
		
};