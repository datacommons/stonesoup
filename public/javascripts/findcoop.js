// tiny part of email obfuscation
function missive(address) {
    document.location.href = 'mail'+'to:'+address;
}

// trivial functions for import interface
function showSavingButton(buttonname) {
    var button = document.getElementById(buttonname);
    button.value = 'Saving...'; 
    button.disabled = true;
}
function resetSaveButton(buttonname) {
    var button = document.getElementById(buttonname);
    button.value = 'Save'; 
    button.disabled = false;
}
function showFailure(message) {
    document.getElementById("ajax_result").innerHTML = message;
}

String.prototype.hashCode = function(){
    var hash = 0;
    for (var i = 0; i < this.length; i++) {
	var ch = this.charCodeAt(i);
	hash = ((hash<<5)-hash)+ch;
	hash = hash & hash;
    }
    return hash;
}

function cache_filter_option(obj,txt) {
  var at = obj["id_cache_ct"] || 0;
  var c = obj["id_cache"];
  if (typeof(c)=="undefined") { c = obj["id_cache"] = {}; }
  var r = c[txt];
  if (typeof(r)=="undefined") { 
    r = c[txt] = at;  
    obj["id_cache_ct"] = at+1;
  }
  return r;
}

