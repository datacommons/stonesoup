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


