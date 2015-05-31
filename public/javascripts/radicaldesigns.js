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
 
});