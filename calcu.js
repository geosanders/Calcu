
/* state of the calculator, set initially by a key_clear */
var CALC_STATE = {
	operator: null,
	operands: [0],
	readout: '0',
};

/* map key combinations to buttons and data */
var KEY_DATA = {
	key_backspace: { keys:[{code:8,shift:0}], action: 'backspace' },
	key_clear: { keys:[{code:12,shift:1},{code:27,shift:0}], action: 'clear' },
	key_divide: { keys:[{code:111,shift:0},{code:191,shift:0}], action: 'setop', op:'/' },
	key_times: { keys:[{code:106,shift:0}], action: 'setop', op:'*' },
	key_minus: { keys:[{code:109,shift:0}], action: 'setop', op:'-' },
	key_plus: { keys:[{code:107,shift:0}], action: 'setop', op:'+' },
	key_equals: { keys:[{code:13,shift:0}], action: 'equals' },
	key_period: { keys:[{code:110,shift:0},{code:190,shift:0}], action: 'append', item:'.' },
	key_0: { keys:[{code:96,shift:0},{code:48,shift:0}], action: 'append', item: '0' },
	key_1: { keys:[{code:97,shift:0},{code:49,shift:0}], action: 'append', item: '1' },
	key_2: { keys:[{code:98,shift:0},{code:50,shift:0}], action: 'append', item: '2' },
	key_3: { keys:[{code:99,shift:0},{code:51,shift:0}], action: 'append', item: '3' },
	key_4: { keys:[{code:100,shift:0},{code:52,shift:0}], action: 'append', item: '4' },
	key_5: { keys:[{code:101,shift:0},{code:53,shift:0}], action: 'append', item: '5' },
	key_6: { keys:[{code:102,shift:0},{code:54,shift:0}], action: 'append', item: '6' },
	key_7: { keys:[{code:103,shift:0},{code:55,shift:0}], action: 'append', item: '7' },
	key_8: { keys:[{code:104,shift:0},{code:56,shift:0}], action: 'append', item: '8' },
	key_9: { keys:[{code:105,shift:0},{code:57,shift:0}], action: 'append', item: '9' },
};

function keyStateDown(aKeyName) {
	$('#'+aKeyName).addClass('down');
}

function keyStateUp(aKeyName) {
	$('#'+aKeyName).removeClass('down');
	var myData = KEY_DATA[aKeyName];
	if (myData) {
		processButtonPress(myData);
	}
	else {
		console.log("got keyStateUp for an unrecognized key name: " + aKeyName);
	}
}

/**
 * Process a button press appropriately
 */
function processButtonPress(aButtonData) {

	if (aButtonData.action == 'append') {
		var r = CALC_STATE.readout;
		if (r == '0') {
			r = aButtonData.item;
		}
		else {

			// handle period separately
			if (aButtonData.item == '.') {
				// can't add two periods to a number
				if (r.indexOf('.') < 0) {
					r += aButtonData.item;
				}
			}

			// otherwise just append
			else {
				r += aButtonData.item;
			}
		}
		// discard this change if it's now too long
		if (r.length < 12) {
			CALC_STATE.readout = r;
		}
	}
	else if (aButtonData.action == 'backspace') {
		var r = CALC_STATE.readout;
		if (r.length > 1) {
			r = r.substring(0, r.length-1);
		}
		else {
			r = '0';
		}
		CALC_STATE.readout = r;
	}
	else if (aButtonData.action == 'clear') {
		CALC_STATE.operator = null;
		CALC_STATE.readout = '0';
	}
	else if (aButtonData.action == 'setop') {
		CALC_STATE.operator = aButtonData.op;
	}
	else if (aButtonData.action == 'equals') {
	}
	else {
		console.log("unrecognized action: " + aButtonData.action);
	}

	updateDisplay();

}


function updateDisplay() {

	/////////////////////////////////////////////
	// update operator in display
	var mySymbol = '';
	if (CALC_STATE.operator == '/') {
		mySymbol = '&divide;';
	}
	else if (CALC_STATE.operator == '*') {
		mySymbol = '&times;';
	}
	else if (CALC_STATE.operator == '-') {
		mySymbol = '&minus;';
	}
	else {
		mySymbol = CALC_STATE.operator;
	}

	if (mySymbol == null) { mySymbol = ''; }

	$('#readout_op').html('<div class="inner">'+mySymbol+'</div>');

	////////////////////////////////////////////
	// update the readout
	var myReadoutHtml = CALC_STATE.readout;
	$('#readout').html('<div class="inner">'+myReadoutHtml+'</div>');

}


$(function() {

	// $('#main').hide().fadeIn();

	$(document).keydown(function(e) {
		console.log("Key down: " + e.keyCode);
		for (var i in KEY_DATA) {
			for (var j in KEY_DATA[i].keys) {
				var myKeyData = KEY_DATA[i].keys[j];
				if (myKeyData.code == e.keyCode && ((!!myKeyData.shift) == (!!e.shiftKey))) {
					keyStateDown(i);
					e.preventDefault();
				}
			}
		}
		// switch (e.keyCode) {
		// 	case 12: case 27: { keyStateDown('key_clear'); } break;
		// 	case 110: case 190: { keyStateDown('key_period'); } break;
		// 	case 111: case 191: { keyStateDown('key_divide'); } break;
		// 	case 106: { keyStateDown('key_times'); } break;
		// 	case 96: case 48: { keyStateDown('key_0'); } break;
		// 	case 97: case 49: { keyStateDown('key_1'); } break;
		// 	case 98: case 50: { keyStateDown('key_2'); } break;
		// 	case 99: case 51: { keyStateDown('key_3'); } break;
		// 	case 100: case 52: { keyStateDown('key_4'); } break;
		// 	case 101: case 53: { keyStateDown('key_5'); } break;
		// 	case 102: case 54: { keyStateDown('key_6'); } break;
		// 	case 103: case 55: { keyStateDown('key_7'); } break;
		// 	case 104: case 56: { keyStateDown('key_8'); } break;
		// 	case 105: case 57: { keyStateDown('key_9'); } break;
		// }
	});

	$(document).keyup(function(e) {

		for (var i in KEY_DATA) {
			for (var j in KEY_DATA[i].keys) {
				var myKeyData = KEY_DATA[i].keys[j];
				if (myKeyData.code == e.keyCode && ((!!myKeyData.shift) == (!!e.shiftKey))) {
					keyStateUp(i);
					e.preventDefault();
				}
			}
		}

	});

	$('.key').mousedown(function(e) {
		if (e.target && e.target.id && (e.target.id+'').match(/^key_/)) {
			keyStateDown(e.target.id);
		}
	});

	$('.key').mouseup(function(e) {
		if (e.target && e.target.id && (e.target.id+'').match(/^key_/)) {
			keyStateUp(e.target.id);
		}
	});

	// clear everything out
	processButtonPress(KEY_DATA.key_clear);

	// do the initial display update
	updateDisplay();

});
