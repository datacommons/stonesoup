jQuery(document).ready(function(){
 
    /** This script allows the sidebar on the home page map to open and close **/
    jQuery(".close-box").show();
    jQuery(".close-box").append( "x" );
    jQuery("#add_se .open-box").append( "&#x25b6;" );

    jQuery('.close-box').click(function(){
    	jQuery("#map-text-box, #add_se #login").toggle('slide');
    	jQuery(".open-box").show();
    });
    jQuery('.open-box').click(function(){
	    jQuery("#map-text-box, #add_se #login").toggle('slide');
	    jQuery(".open-box").hide();
	 });
	 
	/** This script allows the categories to toggle visibility on search results pages **/
	jQuery('#meta_inner').hide();
	jQuery('#search_meta h3').click(function(){
	    jQuery('#search_meta h3').toggleClass('open');
	    jQuery('#meta_inner').toggle('clip');
	 });  
	 
	/** These functions ensure that our map takes up the full size of the browser viewport, and will resize dynamically if the user adjusts thier browser size **/ 
	function map_height() {
		var header = jQuery('#header').height();
		var footer = jQuery('#footer').height();
	    var height = jQuery(window).height();
	    var map_height = parseInt((height) - (header) - (footer)) + 'px';
	    jQuery("#big_front_map").css('height',map_height);
	}
    map_height();
    jQuery(window).bind('resize', map_height);
    
    function search_map_height() {
		var header = jQuery('#header').height();
		var criteria = jQuery('#search_criteria').height() + jQuery('#search_criteria').outerHeight() + jQuery('#search_meta h3').height() - 10;
	    var height = jQuery(window).height();
	    var search_map_height = parseInt((height) - (header) - (criteria)) + 'px';
	    jQuery(".page-search-search #the_map, .section-org_types #the_map").css('height',search_map_height);
	}
    search_map_height();
    jQuery(window).bind('resize', search_map_height);
    
    
    /** This function makes sure our footer is sticking to the bottom, so hat we do not end up with awkward white space on pages that have little content **/
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
	
	/** This function keeps he "Be on the Map" box in place where we want it in its container depending on screen height **/
	function sticky_add() {
		var sidebar_height = parseInt(jQuery('#map-text-box').height() - jQuery('#map-text-box p').height() - jQuery('#map-text-box h4').height() - jQuery('#map-text-box h4').outerHeight() - jQuery('#login').height());
		var min_height = parseInt(jQuery('#map-text-box').height());
		var elements_height = parseInt(jQuery('#map-text-box p').height() + jQuery('#map-text-box h4').height() + jQuery('#map-text-box h4').outerHeight() + jQuery('#login').height());
		if(min_height > elements_height){
			jQuery("#login").css({
				'margin-top': sidebar_height
				});
		}
	}
	sticky_add();
	jQuery(window).bind('resize', sticky_add);
	
	/** This function lets anchors scroll prettily to thier location below the fold on search results pages **/
	function graceful_scroll() {
		jQuery('#list_results a').click(function(){
	    	jQuery('html, body').animate({
	        	scrollTop: jQuery( jQuery(this).attr('href') ).offset().top
	    }, 1000);
	    return false;
		});
	};
	graceful_scroll();

	if ( jQuery("#big_front_map").length ){
		show_continental_US_map('big_front_map');   
	}
});