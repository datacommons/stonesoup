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
	    var map_height = (height) - (header) - (footer);
	    map_height = parseInt(map_height) + 'px';
	    jQuery("#big_front_map").css('height',map_height);
	}
    map_height();
    jQuery(window).bind('resize', map_height);
});