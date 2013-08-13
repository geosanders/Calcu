
function keyStateDown(aKeyName) {
	//console.log("HERE:");
	$('#'+aKeyName).addClass('down');
}

function keyStateUp(aKeyName) {
	$('#'+aKeyName).removeClass('down');
}

$(function() {

	// $('#main').hide().fadeIn();

	$(document).keydown(function(e) {
		switch (e.keyCode) {
			case 97: {
				keyStateDown('key_1');
			} break;
		}
	});

	$(document).keyup(function(e) {
		switch (e.keyCode) {
			case 97: {
				keyStateUp('key_1');
			} break;
		}
	});

});
