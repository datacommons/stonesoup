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

/* begin cookie manipulation code from http://snipplr.com/view/2586/ */
function cookieTime(days){
 var now = new Date();
 var exp = new Date();
 var x = Date.parse(now) + days*24*60*60*1000;
 exp.setTime(x);
 str = exp.toUTCString();
 re = '/(\d\d)\s(\w\w\w)\s\d\d(\d\d))/';
 return str.replace(re,"$1-$2-$3");
}
var cookieJar = {
    setState: function ( id, value) {
      document.cookie = id+'='+value+';path=/;expires='+cookieTime(365);
    },
    getState: function( id, defaultState ) {
      var re          = new RegExp(id+'=(.*)');
      var state       = re.exec(document.cookie);
      return (state) ? state[1].split(';')[0] : defaultState;
    }
}
/* end cookie manipulation code from http://snipplr.com/view/2586/ */

var CLIENT_COOKIE_NAME = 'find.coop';
var CLIENT_COOKIE_PAIR_SEPARATOR = '|';
var CLIENT_COOKIE_VALUE_SEPARATOR = '=';
function setClientVar(name, newvalue) {
	// basically, to set a variable we get the current cookie value and set the value for this 'key' and leave the others intact
	var cookieValue = cookieJar.getState(CLIENT_COOKIE_NAME, null);
	//alert("setClientVar("+name+","+newvalue+"): read cookie state as: "+cookieValue);
	var value_pairs;
	if(cookieValue == null) {
		value_pairs = new Array();
	} else {
		value_pairs = cookieValue.split(CLIENT_COOKIE_PAIR_SEPARATOR);
	}
	var new_value_pairs = new Array();
	for (var i = 0; i < value_pairs.length; i++) {
		var pair_array = value_pairs[i].split(CLIENT_COOKIE_VALUE_SEPARATOR);
		var key = pair_array[0];
		var curval = pair_array[1];
		var newval;
		if(key != name) {
			// keep current value for key
			new_value_pairs.push(key+CLIENT_COOKIE_VALUE_SEPARATOR+curval);
		}
	}
	// set new value for our key
	new_value_pairs.push(name+CLIENT_COOKIE_VALUE_SEPARATOR+newvalue);
	// set the new cookie value
	cookieValue = new_value_pairs.join(CLIENT_COOKIE_PAIR_SEPARATOR);
	//alert("setClientVar("+name+","+newvalue+"): setting cookie state as: "+cookieValue);
	cookieJar.setState(CLIENT_COOKIE_NAME, cookieValue);
}
function getClientVar(name) {
	var cookieValue = cookieJar.getState(CLIENT_COOKIE_NAME, null);
	//alert("getClientVar("+name+"): read cookie state as: "+cookieValue);
	if(cookieValue == null) { return null; }
	var value_pairs = cookieValue.split(CLIENT_COOKIE_PAIR_SEPARATOR);
	for (var i = 0; i < value_pairs.length; i++) {
		var pair_array = value_pairs[i].split(CLIENT_COOKIE_VALUE_SEPARATOR);
		if(pair_array[0] == name) {
			//alert("getClientVar("+name+"): returning value as: "+pair_array[1]);
			return pair_array[1];
		}
	}
	return null;
}