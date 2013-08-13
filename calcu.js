
/* map key combinations to buttons and data */
var KEY_DATA = {
	key_clear: { keys:[{code:12,shift:1},{code:27,shift:0}], action: 'clear' },
	key_0: { keys:[{code:96},{code:48,shift:0}], action: 'append', item: '0' },
}

function keyStateDown(aKeyName) {
	//console.log("HERE:");
	$('#'+aKeyName).addClass('down');
}

function keyStateUp(aKeyName) {
	$('#'+aKeyName).removeClass('down');
}

/**
 * Process a button press appropriately
 */
function processButtonPress(aItem) {

}

$(function() {

	// $('#main').hide().fadeIn();

	$(document).keydown(function(e) {
		console.log("Key down for: " + e.keyCode);
		switch (e.keyCode) {
			case 12: case 27: { keyStateDown('key_clear'); } break;
			case 110: case 190: { keyStateDown('key_period'); } break;
			case 111: case 191: { keyStateDown('key_divide'); } break;
			case 106: { keyStateDown('key_times'); } break;
			case 96: case 48: { keyStateDown('key_0'); } break;
			case 97: case 49: { keyStateDown('key_1'); } break;
			case 98: case 50: { keyStateDown('key_2'); } break;
			case 99: case 51: { keyStateDown('key_3'); } break;
			case 100: case 52: { keyStateDown('key_4'); } break;
			case 101: case 53: { keyStateDown('key_5'); } break;
			case 102: case 54: { keyStateDown('key_6'); } break;
			case 103: case 55: { keyStateDown('key_7'); } break;
			case 104: case 56: { keyStateDown('key_8'); } break;
			case 105: case 57: { keyStateDown('key_9'); } break;
		}
	});

	$(document).keyup(function(e) {
		switch (e.keyCode) {
			case 110: case 190: { keyStateUp('key_period'); } break;
			case 96: case 48: { keyStateUp('key_0'); } break;
			case 97: case 49: { keyStateUp('key_1'); } break;
			case 98: case 50: { keyStateUp('key_2'); } break;
			case 99: case 51: { keyStateUp('key_3'); } break;
			case 100: case 52: { keyStateUp('key_4'); } break;
			case 101: case 53: { keyStateUp('key_5'); } break;
			case 102: case 54: { keyStateUp('key_6'); } break;
			case 103: case 55: { keyStateUp('key_7'); } break;
			case 104: case 56: { keyStateUp('key_8'); } break;
			case 105: case 57: { keyStateUp('key_9'); } break;
		}
	});

});
