/**

* DONE - 2 decimal points to disappear
* DONE comma's in large numbers
* DONE operator into the box
* DONE fix CSS on long numbahs (match calculator)
* DONE spacing on totals/subtotals
* implement CE/C, 3 times should clear the whole tape
* add space in, match the C, black

PASS - 		3 4	3 +	5 -	3 x	7 /	4 =	5 *                     338.00
 
666 + 5	+ +	+ -	+ x	+ /	+ =	+ *                 928884.00

666 - 8	- +	- -	- x	6 - 8 / 4 - = - *           -700.00

0.666 x 5 x + x - x x x / x = x *               -7.75

/ 4	/ +	/ -	/ x	/ /	/ =	/ *

= 3	= +	= -	= x	= /	= =	= *

* 4	* +	* -	* x	* /	* =	* *

*/

// the tests are at the bottom of this file
var autotest = true;
var debug = true;

/* state of the calculator, set initially by a key_clear */
var CALC_STATE = {

	lastval: null, // the prior value entered
	curval: null, // the current value you are "typing into" - this is null right after
	           // an operator is executed and before you press another key
	display: '0', // the string used for display


	total: 0, // the running total
	subtotal: null, // subtotal
	lastop: null, // the prior operator entered
	lastkey: null,
	lastEqualOp: null,

	// operands: [0], // the operand stack
	// readout: '0', // the currently in the readout
	// keyPressed: null, // set to the textual code for the key currently pressed
	// state: 'input', // current state:
	// 				//   input (normal mode)
	// 				//   opsetwait (after you set an operator the first time and next key is new number)
	// 				//   postcalc (after a calculation has been made and it's showing the result number)

	emulateKeyPressQueue: [], // queue of key presses to emulate
};

/* map key combinations to buttons and data */
var KEY_DATA = {
	// NOTES: "*" key acts like CE if pressed once and then fully clears if pressed again, with some funky edge cases
	// CE specifically only deletes the current entry but the prior result is still there
	// Hm - "*" is actually the "total" button...
	key_backspace: { keys:[{code:8,shift:0}], action: 'backspace', serialCode: 'bs' },
	key_clear: { keys:[{code:12,shift:1},{code:27,shift:0}], action: 'clear', serialCode: 'ce' },
	key_divide: { keys:[{code:111,shift:0},{code:191,shift:0}], action: 'setop', op:'/', serialCode: 'div' },
	key_times: { keys:[{code:106,shift:0}], action: 'setop', op:'*', serialCode: 'mul' },
	key_minus: { keys:[{code:109,shift:0}], action: 'setop', op:'-', serialCode: '-' },
	key_plus: { keys:[{code:107,shift:0}], action: 'setop', op:'+', serialCode: '+' },
	key_equals: { keys:[{code:13,shift:0}], action: 'equals', serialCode: '=' },
	key_period: { keys:[{code:110,shift:0},{code:190,shift:0}], action: 'append', item:'.', serialCode: '.' },
	key_total: { keys:[{code:84,shift:0}], serialCode: '*' },
	key_00: { keys:[], action: 'append', item: '00', serialCode: '00' },
	key_0: { keys:[{code:96,shift:0},{code:48,shift:0}], action: 'append', item: '0', serialCode: '0' },
	key_1: { keys:[{code:97,shift:0},{code:49,shift:0}], action: 'append', item: '1', serialCode: '1' },
	key_2: { keys:[{code:98,shift:0},{code:50,shift:0}], action: 'append', item: '2', serialCode: '2' },
	key_3: { keys:[{code:99,shift:0},{code:51,shift:0}], action: 'append', item: '3', serialCode: '3' },
	key_4: { keys:[{code:100,shift:0},{code:52,shift:0}], action: 'append', item: '4', serialCode: '4' },
	key_5: { keys:[{code:101,shift:0},{code:53,shift:0}], action: 'append', item: '5', serialCode: '5' },
	key_6: { keys:[{code:102,shift:0},{code:54,shift:0}], action: 'append', item: '6', serialCode: '6' },
	key_7: { keys:[{code:103,shift:0},{code:55,shift:0}], action: 'append', item: '7', serialCode: '7' },
	key_8: { keys:[{code:104,shift:0},{code:56,shift:0}], action: 'append', item: '8', serialCode: '8' },
	key_9: { keys:[{code:105,shift:0},{code:57,shift:0}], action: 'append', item: '9', serialCode: '9' },
};
for (var i in KEY_DATA) {
	KEY_DATA[i].name = i;
}

/**
 * Return the key name that corresponds to a serial code
 */
function getKeyNameFromSerialCode(aSerialCode) {
	for (i in KEY_DATA) {
		if (KEY_DATA[i].serialCode && KEY_DATA[i].serialCode == aSerialCode) {
			return i;
		}
	}
	return null;
}

/**
 * Emulate a full press of a key
 */
function emulateKeyPress(aKeyName) {

	var myNext = null;

	// if the caller provided a key
	if (aKeyName) {
		// if already a queue, then add to end
		if (CALC_STATE.emulateKeyPressQueue.length) {
			CALC_STATE.emulateKeyPressQueue.push(aKeyName);
			// and shift off the next item
			myNext = CALC_STATE.emulateKeyPressQueue.shift();
		}
		// otherwise use what they passed
		else {
			myNext = aKeyName;
		}
	}
	// if no key provided but we have a queue then pull the next
	else if (CALC_STATE.emulateKeyPressQueue.length) {
		myNext = CALC_STATE.emulateKeyPressQueue.shift();
	}

	// if any item to process
	if (myNext) {
		keyStateDown(myNext);
		// setTimeout(function() {
			keyStateUp(myNext);
		// }, 200);
	}

}

function keyStateDown(aKeyName) {
	$('#'+aKeyName).addClass('down');
	CALC_STATE.keyPressed = aKeyName;
}

function keyStateUp(aKeyName) {
	if (!aKeyName) {
		aKeyName = CALC_STATE.keyPressed;
	}
	$('#'+aKeyName).removeClass('down');
	var myData = KEY_DATA[aKeyName];
	if (myData) {
		processButtonPress(myData);
	}
	else {
		console.log("got keyStateUp for an unrecognized key name: " + aKeyName);
	}

	CALC_STATE.keyPressed = null;
}

/**
 * Process a button press appropriately
 */
function processButtonPress(aButtonData) {

	// deep copy the button data
	var myButtonData = $.extend({}, aButtonData);
	// console.log(myButtonData);

	switch (myButtonData.name) {

	    case 'key_00':
	    case 'key_0':
	    case 'key_1':
	    case 'key_2':
	    case 'key_3':
	    case 'key_4':
	    case 'key_5':
	    case 'key_6':
	    case 'key_7':
	    case 'key_8':
	    case 'key_9':
		case 'key_period':

			// ignore the keypress if the display number is already 12 digits
			if (CALC_STATE.display.replace(/\./, '').length >= 12) {
				break;
			}

			if (CALC_STATE.lastkey == 'key_equals') {
				CALC_STATE.subtotal = null;
			}

			// ignore any duplicate periods
			if (myButtonData.name === 'key_period' && CALC_STATE.display.indexOf('.') > -1) break;

	    	if  (
	    			CALC_STATE.lastkey == 'key_plus' ||
	    			CALC_STATE.lastkey == 'key_minus' || 
	    			CALC_STATE.lastkey == 'key_times' ||
	    			CALC_STATE.lastkey == 'key_divide' ||
	    			CALC_STATE.lastkey == 'key_equals' ||
	    			CALC_STATE.lastkey == 'key_total'
	    		) {
	    		CALC_STATE.display = '0';
	    	}

	    	if (CALC_STATE.subtotal == 'key_equals') {
	    		CALC_STATE.subtotal = null;
	    	}
	    	if (CALC_STATE.lastkey == 'key_total') {
	    		CALC_STATE.total = 0;
	    	}

	    	if (CALC_STATE.display == '0') {
	    		CALC_STATE.display = '';
	    	}

	    	CALC_STATE.display += myButtonData.item;
	    	CALC_STATE.curval = parseFloat(CALC_STATE.display);

	    	// minor display tweak
	    	if (CALC_STATE.display === '.') CALC_STATE.display = '0.';

	    	updateDisplay();

	    	break;

		case 'key_backspace':

			break;

		case 'key_plus':

			if (CALC_STATE.lastop == '*') {
				CALC_STATE.funkyMultiply = true;
				CALC_STATE.subtotalSaved = CALC_STATE.subtotal;
				// CALC_STATE.curval = CALC_STATE.subtotal;
			}

			CALC_STATE.subtotal = null;
			
			if (CALC_STATE.lastkey != 'key_total') {
				CALC_STATE.total += CALC_STATE.curval;
				addTapeRow(CALC_STATE.curval, '+', false);
			} else {
				addTapeRow(CALC_STATE.total, '+', false);
			}

			CALC_STATE.display = numberToString(CALC_STATE.total);
			

			CALC_STATE.lastop = '+';
			break;

		case 'key_minus':

			CALC_STATE.subtotal = null;

			CALC_STATE.total -= CALC_STATE.curval;
			CALC_STATE.display = numberToString(CALC_STATE.total);
			addTapeRow(CALC_STATE.curval, '-', false);

			CALC_STATE.lastop = '-';
			break;

		case 'key_equals':

			if  (CALC_STATE.lastkey == 'key_plus' && CALC_STATE.funkyMultiply) {
				addTapeRow(CALC_STATE.total, 'equals', false);
				CALC_STATE.total = CALC_STATE.total * CALC_STATE.subtotalSaved;

				CALC_STATE.subtotal = CALC_STATE.total;
				CALC_STATE.lastCurval = CALC_STATE.subtotalSaved;

				addTapeRow(CALC_STATE.total, 'total', false);
                
				CALC_STATE.lastEqualOp = '*';

			}

			if  (CALC_STATE.lastop == '*') {

				CALC_STATE.lastCurval = CALC_STATE.subtotal;
				CALC_STATE.subtotal *= CALC_STATE.curval;
				CALC_STATE.display = numberToString(CALC_STATE.subtotal);
				addTapeRow(CALC_STATE.curval, 'equals', true);
				addTapeRow(CALC_STATE.subtotal, 'total', false);

				CALC_STATE.lastEqualOp = '*';

			}

			if  (CALC_STATE.lastkey == 'key_plus' && CALC_STATE.funkyMultiply)
				CALC_STATE.display = numberToString(CALC_STATE.total);

			if  (CALC_STATE.lastop == '=' && CALC_STATE.lastEqualOp == '*') {
				addTapeRow(CALC_STATE.subtotal, 'equals', false);
				CALC_STATE.subtotal *= CALC_STATE.lastCurval;
				CALC_STATE.display = numberToString(CALC_STATE.subtotal);
				addTapeRow(CALC_STATE.subtotal, 'total', false);
			}

			if  (CALC_STATE.lastop == '/') {

				CALC_STATE.lastCurval = CALC_STATE.curval;
				CALC_STATE.subtotal = CALC_STATE.subtotal / CALC_STATE.curval;
				CALC_STATE.display = numberToString(CALC_STATE.subtotal);
				addTapeRow(CALC_STATE.curval, 'equals', true);
				addTapeRow(CALC_STATE.subtotal, 'total', false);

				CALC_STATE.lastEqualOp = '/';

			}

			if  (CALC_STATE.lastop == '=' && CALC_STATE.lastEqualOp == '/') {
				addTapeRow(CALC_STATE.subtotal, 'equals', false);
				CALC_STATE.subtotal = CALC_STATE.subtotal / CALC_STATE.lastCurval;
				CALC_STATE.display = numberToString(CALC_STATE.subtotal);
				addTapeRow(CALC_STATE.subtotal, 'total', false);
			}

			CALC_STATE.funkyMultiply = false;

			CALC_STATE.curval = CALC_STATE.subtotal;

			CALC_STATE.lastop = '=';
			break;

		case 'key_times':

			if (CALC_STATE.subtotal == null) CALC_STATE.subtotal = 1;

			if (CALC_STATE.lastop == '/') {
				CALC_STATE.subtotal = CALC_STATE.subtotal / CALC_STATE.curval;
			} else {
				if (CALC_STATE.lastkey == 'key_plus') {
					CALC_STATE.curval = CALC_STATE.total;
				}
				if (CALC_STATE.lastkey != 'key_equals') CALC_STATE.subtotal *= CALC_STATE.curval;
			}

			CALC_STATE.display = numberToString(CALC_STATE.subtotal);
			addTapeRow(CALC_STATE.curval, '*', true);

			CALC_STATE.lastop = '*';
			break;

		case 'key_divide':

			if (CALC_STATE.lastop == '/') {
				CALC_STATE.subtotal = CALC_STATE.subtotal / CALC_STATE.curval;
			} else {
				if (CALC_STATE.lastop == '*') {
					CALC_STATE.subtotal *= CALC_STATE.curval;
				} else {
					if (CALC_STATE.lastkey == 'key_plus') {
						CALC_STATE.curval = CALC_STATE.total;
					}
					CALC_STATE.subtotal = CALC_STATE.curval;
				}
			}

			CALC_STATE.display = numberToString(CALC_STATE.subtotal);
			addTapeRow(CALC_STATE.curval, '/', true);

            // CALC_STATE.curval = CALC_STATE.subtotal;
			
			CALC_STATE.lastop = '/';
			break;

		case 'key_total':
			
			CALC_STATE.display = numberToString(CALC_STATE.total);
			addTapeRow(CALC_STATE.total, 'total', false);

			CALC_STATE.curval = CALC_STATE.total;
			// CALC_STATE.total = 0;
			
			CALC_STATE.lastop = '=';
			CALC_STATE.funkyMultiply = false;
			break;

		case 'key_clear':
			// FIXME: is this "CE" or "C" ? (CE clears one entry whereas C clears everything)
			// FIXME: this isn't exactly right, probably should not clear total, or something

			CALC_STATE.display = '0';
			CALC_STATE.curval = 0;
			CALC_STATE.lastval = null;
			
			if (CALC_STATE.lastkey == 'key_clear') {
				clearTape();
				CALC_STATE.total = 0;
				CALC_STATE.subtotal = null;
				CALC_STATE.lastop = null;
				CALC_STATE.funkyMultiply = false;
			}
		
	}

	CALC_STATE.lastkey = myButtonData.name;

	CALC_STATE.justCleared = false;

	if (debug) {
		console.debug('after operation:');
		console.debug(JSON.stringify(CALC_STATE, null, 4));
	}
	
	updateDisplay();

	return;

}

function updateDisplay() {

	/////////////////////////////////////////////
	// update operator in display
	var mySymbol = '';
	if (CALC_STATE.lastkey == 'key_divide') {
		mySymbol = '&divide;';
	}
	else if (CALC_STATE.lastkey == 'key_times') {
		mySymbol = '&times;';
	}
	else if (CALC_STATE.lastkey == 'key_minus') {
		mySymbol = '&minus;';
	}
	else if (CALC_STATE.lastkey == 'key_plus') {
		mySymbol = '&plus;';
	}
	else if (CALC_STATE.lastkey == 'key_equals') {
		mySymbol = '=';
	}
	else if (CALC_STATE.lastkey == 'key_total') {
		mySymbol = '*';
	}

	if (mySymbol == null) { mySymbol = ''; }

	$('#readout_op').html('<div class="inner">'+mySymbol+'</div>');

	////////////////////////////////////////////
	// update the readout

	var myReadoutHtml = CALC_STATE.display;

	// put in thousand separators
	var decimals = (myReadoutHtml.indexOf('.') > -1);
	var currentDigit = 0;
	var currentString = '';
	for (var i = myReadoutHtml.length - 1; i >= 0; i--) {
		var myChar = myReadoutHtml[i];
		if (decimals && myChar != '.') {
			currentString = myChar + currentString;
			continue;
		}
		if (decimals && myChar == '.') {
			decimals = false;
			currentString = myChar + currentString;
			continue;
		}

		currentString = myChar + currentString;
		if (currentDigit % 3 == 2) currentString = '<span class="thousand-sep"></span>' + currentString;
		currentDigit++;
	};
	myReadoutHtml = currentString.replace(/^([-]?)<span[^<]*<\/span>/, function(rep1, rep2) {
		return rep2;
	}); // <- rip any initial thousand separators

	$('#readout').html('<div class="inner">'+myReadoutHtml+'</div>');

}

// borrowed from: http://stackoverflow.com/questions/2221167/javascript-formatting-a-rounded-number-to-n-decimals/2909252#2909252
function toFixed(value, precision) {
    var precision = precision || 0,
    neg = value < 0,
    power = Math.pow(10, precision),
    value = Math.round(value * power),
    integral = String((neg ? Math.ceil : Math.floor)(value / power)),
    fraction = String((neg ? -value : value) % power),
    padding = new Array(Math.max(precision - fraction.length, 0) + 1).join('0');

    return precision ? integral + '.' +  padding + fraction : integral;
}

/**
 * Apply an operator to two numbers
 */
function applyOperator(aOperator, aOperand1, aOperand2) {

	switch (aOperator) {
		case 'times':
		case 'mul':
		case '*':
			return aOperand1 * aOperand2;
		case 'divide':
		case 'div':
		case '/':
			return aOperand1 / aOperand2;
		case 'plus':
		case '+':
			return aOperand1 + aOperand2;
		case 'minus':
		case '-':
			return aOperand1 - aOperand2;
		default:
			console.log("Can't apply operator: " + aOperator);
			return aOperand1;
	}

}

/** return number to two decimal places */
function roundNumber(v) {
	return parseFloat(parseFloat(v).toFixed(2));
}

/** return a user-friendly display of a number */
function numberToString(v, abbreviate) {

	if (v === null) v = 0;

	var res = toFixed(roundNumber(v), 2);

	// chop off the '.00' from the end
	if (abbreviate && res.length > 3 && res.substring(res.length - 3) == '.00') {
		res = res.substring(0, res.length - 3);
	}

	// if it's over 12 characters with decimals (1-2 decimals over) - chop those off
	if (res.indexOf('.' > -1)) res = res.substring(0, 13);

	return res;

	// var r = roundNumber(v)+'';
	// if (r.match(/\.00/)) {
	// 	r = r.substring(0, r.length-3);
	// }
	// else if (r.match(/\.[0-9]0/)) {
	// 	r = r.substring(0, r.length-1);
	// }

	// return r;

}



/**
 * Add a row to the tape thing
 */
function addTapeRow(aValue, aType, abbreviate) {
	
	var myType = aType;
	if (myType == '*') {
		myType = 'times';
	}
	else if (myType == '/') {
		myType = 'divide';
	}
	else if (myType == '+') {
		myType = 'plus';
	}
	else if (myType == '-') {
		myType = 'minus';
	}
	else if (myType == '=') {
		myType = 'equals';
	}

	var myRow = $('<div class="row"></div>');

	myRow.addClass(myType);

	var v = aValue ? numberToString(aValue, abbreviate) : (aValue === null ? '0' : aValue);
	
	if (myType == 'regular') {
		v += '&nbsp;&nbsp;&nbsp;';
	}
	else if (myType == 'total') {
		v += ' *';
	}
	else if (myType == 'plus') {
		v += ' +';
	}
	else if (myType == 'minus') {
		v += ' -';
	}
	else if (myType == 'times') {
		v += ' &times;';
	}
	else if (myType == 'divide') {
		v += ' &divide;';
	}
	else if (myType == 'equals') {
		v += ' =';
	}

	myRow.html(v);

	var myTapeDetailEl = document.getElementById('tape_detail');

	$(myTapeDetailEl).append(myRow);

	myTapeDetailEl.scrollTop = myTapeDetailEl.scrollHeight;
}

/**
 * Clear the tape
 */
function clearTape() {
	$('#tape_detail').html('');

}


var ws;

function setupWebsocket() {

	if (typeof MozWebSocket != 'undefined') {
		ws = new MozWebSocket('ws://'+window.location.host+'/serial-relay');
	} else {
		ws = new WebSocket('ws://'+window.location.host+'/serial-relay');
	}

	// When the connection is open, send some data to the server
	ws.onopen = function () {
		// console.log("Socket opened successfully")
	};

	// Log errors
	ws.onerror = function (error) {
	  // console.log('WebSocket Error ' + error + ' (will retry shortly)');
	  setTimeout(function() {
	  	setupWebsocket();
	  }, 3000);
	};

	ws.onclose = function() {
		// console.log("Socket closed, not reconnecting since it was an intentional close");
	}

	// Log messages from the server
	ws.onmessage = function (e) {
		var myData = (e.data+'').toLowerCase();
		var myKeyName = getKeyNameFromSerialCode(myData);
		if (myKeyName) {
			// console.log("Emulating key press: " + myKeyName);
			emulateKeyPress(myKeyName);
		}
		else {
			console.log("No key name could be found for serial code: " + myData);
		}
		// console.log('Ack back from server: ' + e.data);
	};

}

$(function() {

	// $('#main').hide().fadeIn();

	setupWebsocket();

	$(document).keydown(function(e) {
		// console.log("Key down: " + e.keyCode);
		for (var i in KEY_DATA) {
			for (var j in KEY_DATA[i].keys) {
				var myKeyData = KEY_DATA[i].keys[j];
				if (myKeyData.code == e.keyCode && ((!!myKeyData.shift) == (!!e.shiftKey))) {
					keyStateDown(i);
					e.preventDefault();
				}
			}
		}
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
			keyStateUp(null);
		}
	});

	document.ontouchstart = function(e) {
    	e.preventDefault();
		if (e.target && e.target.id && (e.target.id+'').match(/^key_/)) {
			keyStateDown(e.target.id);
		}
	}

	document.ontouchend = function(e) {
    	e.preventDefault();
		if (e.target && e.target.id && (e.target.id+'').match(/^key_/)) {
			keyStateUp(null);
		}
	}

	// clear everything out
	processButtonPress(KEY_DATA.key_clear);

	// do the initial display update
	updateDisplay();

	// clear the tape out
	clearTape();

});

if (autotest) {
	setTimeout(function() {

		CALC_STATE.emulateKeyPressQueue = ['key_2', 'key_times', 'key_4', 'key_plus', 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 8);
		if (CALC_STATE.total != 8) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus', 'key_4', 'key_plus', 'key_5', 'key_minus', 'key_total'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 1);
		if (CALC_STATE.total != 1) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_plus', 'key_1', 'key_plus', 'key_1', 'key_plus', 'key_1', 'key_plus',
			'key_4', 'key_times', 'key_5', 'key_plus', 'key_5', 'key_plus', 'key_5', 'key_plus',
			 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 76);
		if (CALC_STATE.total != 76) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus', 'key_4', 'key_times',
			'key_5', 'key_plus', 'key_5', 'key_plus', 'key_5', 'key_plus',
			 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 68);
		if (CALC_STATE.total != 68) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_times', 'key_plus', 'key_plus',
			'key_equals', 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 16);
		if (CALC_STATE.subtotal != 16) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_0', 'key_0', 'key_0', 'key_divide',
			'key_1', 'key_0', 'key_divide',
			'key_divide',
			'key_divide',
			'key_divide',
			'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 0.01);
		if (CALC_STATE.subtotal != 0.01) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_times',
			'key_5', 'key_times',
			'key_times',
			'key_times',
			'key_times'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 1250);
		if (CALC_STATE.subtotal != 1250) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_times',
			'key_5', 'key_times',
			'key_equals',
			'key_equals',
			'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 5000);
		if (CALC_STATE.subtotal != 5000) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_5', 'key_times', 'key_3', 'key_0', 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 750);
		if (CALC_STATE.subtotal != 750) return;

		CALC_STATE.emulateKeyPressQueue = [
			'key_2', 'key_5', 'key_times', 'key_3', 'key_0', 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 750);
		if (CALC_STATE.subtotal != 750) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_4', 'key_5', 'key_plus', 'key_1', 'key_9', 'key_plus', 
			'key_divide', 'key_8', 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 8);
		if (CALC_STATE.subtotal != 8) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_times', 'key_4', 'key_plus', 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 8);
		if (CALC_STATE.total != 8) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus',
			'key_3', 'key_times',
			'key_4', 'key_equals',
			'key_plus',
			'key_5', 'key_minus',
			'key_total'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 9);
		if (CALC_STATE.total != 9) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_8', 'key_divide',
			'key_3', 'key_times',
			'key_3', 'key_period', 'key_7', 'key_equals',
			'key_plus',
			'key_9', 'key_plus',
			'key_total'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 18.866666666666667);
		if (CALC_STATE.total != 18.866666666666667) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_2', 'key_3', 'key_times',
			'key_7', 'key_5', 'key_6', 'key_clear',
			'key_4', 'key_5', 'key_6', 'key_equals',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 56088);
		if (CALC_STATE.subtotal != 56088) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_3', 'key_4', 'key_3', 'key_plus',
			'key_5', 'key_minus',
			'key_3', 'key_times',
			'key_7', 'key_divide',
			'key_4', 'key_equals',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 5.25);
		if (CALC_STATE.subtotal != 5.25) return;

		CALC_STATE.emulateKeyPressQueue = [
			'key_5', 'key_total',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 338);
		if (CALC_STATE.total != 338) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_6', 'key_6', 'key_6',
			'key_minus', 'key_8',
			'key_minus', 'key_plus',
			'key_minus', 'key_minus',
			'key_minus', 'key_times',
			'key_6', 'key_minus', 'key_8', 'key_divide', 'key_4',
			'key_minus', 'key_equals', 'key_minus', 'key_total'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		// console.assert(CALC_STATE.total == -707.88);
		// if (CALC_STATE.total != -707.88) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.warn('ALL TESTS PASSED');


/**

---

15 x
x
+ (225)

---

**/


	}, 500);
}
// console.error('3 4	3 +	5 -	3 x	7 /	4 =	5 *');
