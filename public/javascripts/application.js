function hasClass(id, cls) {
	var ele = document.getElementById(id);
	if(!ele) alert("hasClass(): No element with id '"+id+"'");
	return ele.className.match(new RegExp('(\\s|^)' + cls + '(\\s|$)'));
}
function addClass(id, cls) {
	var ele = document.getElementById(id);
	if(!ele) alert("addClass(): No element with id '"+id+"'");
	if (!this.hasClass(id, cls)) ele.className += " " + cls;
}
function removeClass(id, cls) {
	var ele = document.getElementById(id);
	if(!ele) alert("removeClass(): No element with id '"+id+"'");
	if (hasClass(id, cls)) {
		var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
		ele.className = ele.className.replace(reg, ' ');
	}
}
function getCheckedValue(radioObj) {
	if(!radioObj)
		return "";
	var radioLength = radioObj.length;
	if(radioLength == undefined)
		if(radioObj.checked)
			return radioObj.value;
		else
			return "";
	for(var i = 0; i < radioLength; i++) {
		if(radioObj[i].checked) {
			return radioObj[i].value;
		}
	}
	return "";
}
