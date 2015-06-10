jQuery(document).ready(function(){
 
    jQuery("#map-text-box").show();
    jQuery(".close-box").show();

    jQuery('.close-box').click(function(){
    	jQuery("#map-text-box").toggle('slide');
    	jQuery(".open-box").show();
    });
    jQuery('.open-box').click(function(){
	    jQuery("#map-text-box").toggle('slide');
	    jQuery(".open-box").hide();
	 });
	 
	function map_height() {
		var header = jQuery('#header').height();
		var footer = jQuery('#footer').height();
	    var height = jQuery(window).height();
	    var map_height = parseInt((height) - (header) - (footer)) + 'px';
	    jQuery("#big_front_map").css('height',map_height);
	}
    map_height();
    jQuery(window).bind('resize', map_height);
    
	function sticky_footer() {
		var content_height = parseInt(jQuery(window).height() - jQuery("#maincol").outerHeight() - jQuery("#header").height() - jQuery("#footer").height());
		if(jQuery("#maincol").height() < content_height){
			jQuery("#footer").css({
				'margin-top': content_height
			});
		}
	}
	sticky_footer();
	jQuery(window).bind('resize', sticky_footer);
});