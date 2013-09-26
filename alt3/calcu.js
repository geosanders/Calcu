/**

* DONE - 2 decimal points to disappear
* DONE comma's in large numbers
* DONE operator into the box
* DONE fix CSS on long numbahs (match calculator)
* DONE spacing on totals/subtotals
* DONE implement CE/C, 3 times should clear the whole tape
* add space in, match the C, black

PASS - 343 + 5 - 3 x 7 / 4 = 5 t              338.00
PASS - 666 + 5 + + + - + x + / + = + t        928884.00
PASS - 666 - 8 - + - - - x 6 - 8 / 4 - = - t  -707.88
PASS - 0.666 x 5 x + x - x x x / x = x t      -7.75

/ 4 / + / - / x / / / = / t
= 3 = + = - = x = / = = = t
15 + 14 t 4 t + t - t x t / t = t t

TODO
* thousand separators
* plus/minus
* percentage - edge cases

*/

// the tests are at the bottom of this file
var autotest = false;
var debug = false;

/* state of the calculator, set initially by a key_clear */
var CALC_STATE = {

	curval: null,    		// the current value you are "typing into" - this is null right after
	           	     		// an operator is executed and before you press another key
	display: '0',    		// the string used for display
	total: 0,        		// total (for the +/-)
	subtotal: null,  		// subtotal (for the * and /)
	lastop: null,    		// the prior operator entered
	lastkey: null,   		// the last key pressed
	lastMultTop: null, 		// the last * or / used (or null if there's no current such operator in force)
	
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
	key_backspace: { keys:[{code:8,shift:0}], action: 'backspace', serialCode: '>' },
	key_clear: { keys:[{code:12,shift:1},{code:27,shift:0}], action: 'clear', serialCode: 'ce' },
	key_divide: { keys:[{code:111,shift:0},{code:191,shift:0}], action: 'setop', op:'/', serialCode: 'div' },
	key_times: { keys:[{code:106,shift:0}], action: 'setop', op:'*', serialCode: 'mul' },
	key_minus: { keys:[{code:109,shift:0}], action: 'setop', op:'-', serialCode: '-' },
	key_plus: { keys:[{code:107,shift:0}], action: 'setop', op:'+', serialCode: '+' },
	key_equals: { keys:[{code:13,shift:0}], action: 'equals', serialCode: '=' },
	key_period: { keys:[{code:110,shift:0},{code:190,shift:0}], action: 'append', item:'.', serialCode: '.' },
	key_total: { keys:[{code:84,shift:0}], serialCode: '*' },
	key_percent: { keys:[{code:53,shift:0}], serialCode: '%' },
	key_00: { keys:[], action: 'append', item: '00', serialCode: '00' },
	key_0: { keys:[{code:96,shift:0},{code:48,shift:0}], action: 'append', item: '0', serialCode: '0' },
	key_1: { keys:[{code:97,shift:0},{code:49,shift:0}], action: 'append', item: '1', serialCode: '1' },
	key_2: { keys:[{code:98,shift:0},{code:50,shift:0}], action: 'append', item: '2', serialCode: '2' },
	key_3: { keys:[{code:99,shift:0},{code:51,shift:0}], action: 'append', item: '3', serialCode: '3' },
	key_4: { keys:[{code:100,shift:0},{code:52,shift:0}], action: 'append', item: '4', serialCode: '4' },
	key_5: { keys:[{code:101,shift:0}], action: 'append', item: '5', serialCode: '5' },
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
	if (debug) console.info('HIT: ' + myNext);

	if (myNext) {
		keyStateDown(myNext);
		setTimeout(function() {
			keyStateUp(myNext);
		}, 200);
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

			if (CALC_STATE.lastkey == 'key_equals') {
				CALC_STATE.lastMultTop = null;
			}

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

	    	// ignore the keypress if the display number is already 12 digits
			if (CALC_STATE.display.replace(/\./, '').length >= 12) {
				break;
			}

	    	if (CALC_STATE.lastkey == 'key_total') {
	    		CALC_STATE.total = 0;
	    	}

	    	if (CALC_STATE.display == '0') {
	    		CALC_STATE.display = '';
	    	}

	    	// ignore any duplicate periods
			if (myButtonData.name === 'key_period' && CALC_STATE.display.indexOf('.') > -1) break;

	    	CALC_STATE.display += myButtonData.item;
	    	CALC_STATE.curval = parseFloat(CALC_STATE.display);

	    	// minor display tweak
	    	if (CALC_STATE.display === '.') CALC_STATE.display = '0.';

	    	updateDisplay();

	    	break;

		case 'key_backspace':

			if (CALC_STATE.lastkey == 'key_00' ||
	    		CALC_STATE.lastkey == 'key_0' ||
	    		CALC_STATE.lastkey == 'key_1' ||
	    		CALC_STATE.lastkey == 'key_2' ||
	    		CALC_STATE.lastkey == 'key_3' ||
	    		CALC_STATE.lastkey == 'key_4' ||
	    		CALC_STATE.lastkey == 'key_5' ||
	    		CALC_STATE.lastkey == 'key_6' ||
	    		CALC_STATE.lastkey == 'key_7' ||
	    		CALC_STATE.lastkey == 'key_8' ||
	    		CALC_STATE.lastkey == 'key_9' ||
				CALC_STATE.lastkey == 'key_period') {

				var currentDisplay = CALC_STATE.display;
				if (currentDisplay != '0')
					CALC_STATE.display = currentDisplay.substring(0, currentDisplay.length-1);
				if (CALC_STATE.display == '') CALC_STATE.display = '0';

				updateDisplay();
			}
			return;
			break;

		case 'key_plus':

			if (CALC_STATE.lastkey != 'key_total') {

				var currentVal = CALC_STATE.curval;

				if (CALC_STATE.lastkey == 'key_times' || CALC_STATE.lastkey == 'key_divide') {
					currentVal = CALC_STATE.subtotal;
				}
				
				if (CALC_STATE.lastkey == 'key_equals') {
					CALC_STATE.curval = CALC_STATE.subtotal;
					currentVal = CALC_STATE.subtotal;
					// CALC_STATE.subtotal = CALC_STATE.multiplier;
				}
				
				CALC_STATE.total += currentVal;
				addTapeRow(currentVal, '+', false);

			} else {
				addTapeRow(CALC_STATE.total, '+', false);
			}

			CALC_STATE.display = numberToString(CALC_STATE.total);
			
			CALC_STATE.lastop = '+';
			break;

		case 'key_minus':

			if (CALC_STATE.lastkey != 'key_total') {

				var currentVal = CALC_STATE.curval;

				if (CALC_STATE.lastkey == 'key_times' || CALC_STATE.lastkey == 'key_divide') {
					currentVal = CALC_STATE.subtotal;
				}
				
				if (CALC_STATE.lastkey == 'key_equals') {
					CALC_STATE.curval = CALC_STATE.subtotal;
					currentVal = CALC_STATE.subtotal;
					// CALC_STATE.subtotal = CALC_STATE.multiplier;
				}

				CALC_STATE.total -= currentVal;
				addTapeRow(currentVal, '-', false);

			} else {
				addTapeRow(CALC_STATE.total, '-', false);
			}

			CALC_STATE.display = numberToString(CALC_STATE.total);
			
			CALC_STATE.lastop = '-';
			break;

		case 'key_times':

			if (CALC_STATE.lastkey == 'key_plus' || CALC_STATE.lastkey == 'key_minus' ||
					CALC_STATE.lastkey == 'key_equals')
				CALC_STATE.curval = CALC_STATE.total;

			if (!CALC_STATE.lastMultTop) {
				CALC_STATE.subtotal = CALC_STATE.curval;
				addTapeRow(CALC_STATE.curval, '*', true);
			} else {
				if (CALC_STATE.lastkey != 'key_equals' && CALC_STATE.lastkey != 'key_percent') {
					CALC_STATE.subtotal = executeOp(CALC_STATE.curval, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
					addTapeRow(CALC_STATE.curval, '*', true);
				} else {
					addTapeRow(CALC_STATE.subtotal, '*', true);
				}
			}
			
			CALC_STATE.multiplier = CALC_STATE.subtotal;
			CALC_STATE.lastMultTop = '*';
			
			CALC_STATE.display = numberToString(CALC_STATE.subtotal);
			CALC_STATE.lastop = '*';
			
			break;

		case 'key_divide':

			if (CALC_STATE.lastkey == 'key_plus' || CALC_STATE.lastkey == 'key_minus' ||
					CALC_STATE.lastkey == 'key_equals')
				CALC_STATE.curval = CALC_STATE.total;

			if (!CALC_STATE.lastMultTop) {
				CALC_STATE.subtotal = CALC_STATE.curval;
				addTapeRow(CALC_STATE.curval, '/', true);
			} else {
				if (CALC_STATE.lastkey != 'key_equals' && CALC_STATE.lastkey != 'key_percent') {
					CALC_STATE.subtotal = executeOp(CALC_STATE.curval, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
					addTapeRow(CALC_STATE.curval, '/', true);
				} else {
					addTapeRow(CALC_STATE.subtotal, '/', true);
				}
			}
			
			CALC_STATE.multiplier = CALC_STATE.curval;
			CALC_STATE.lastMultTop = '/';
			
			CALC_STATE.display = numberToString(CALC_STATE.subtotal);
			CALC_STATE.lastop = '/';
			
			break;

		case 'key_percent':

			if (CALC_STATE.lastop == '*') {

				addTapeRow(CALC_STATE.curval, '%', true);

				/*
				if (CALC_STATE.lastkey == 'key_plus' || CALC_STATE.lastkey == 'key_minus' ||
					CALC_STATE.lastkey == 'key_equals')
					CALC_STATE.curval = CALC_STATE.total;
				*/
	
				CALC_STATE.curval = CALC_STATE.curval / 100;
				CALC_STATE.subtotal = executeOp(CALC_STATE.curval, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
				CALC_STATE.lastMultTop = '*';
				
				addTapeRow(CALC_STATE.subtotal, 'total', true);
				CALC_STATE.display = numberToString(CALC_STATE.subtotal);
				CALC_STATE.lastop = '*';

			}

			if (CALC_STATE.lastop == '/') {

				addTapeRow(CALC_STATE.curval, '%', true);

				/*
				if (CALC_STATE.lastkey == 'key_plus' || CALC_STATE.lastkey == 'key_minus' ||
					CALC_STATE.lastkey == 'key_equals')
					CALC_STATE.curval = CALC_STATE.total;
				*/

				CALC_STATE.curval = CALC_STATE.curval / 100; 
				CALC_STATE.subtotal = executeOp(CALC_STATE.curval, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
				CALC_STATE.lastMultTop = '/';
				
				addTapeRow(CALC_STATE.subtotal, 'total', true);
				CALC_STATE.display = numberToString(CALC_STATE.subtotal);
				CALC_STATE.lastop = '/';

			}
			
			break;

		case 'key_equals':

			if (CALC_STATE.lastMultTop) {

				if (CALC_STATE.lastkey == 'key_plus' || CALC_STATE.lastkey == 'key_minus') {

					if (CALC_STATE.lastMultTop == '*') {
						CALC_STATE.subtotal = executeOp(CALC_STATE.multiplier, CALC_STATE.lastMultTop, CALC_STATE.total);
						addTapeRow(CALC_STATE.multiplier, 'equals', true);
					} else {
						CALC_STATE.subtotal = executeOp(CALC_STATE.total, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
						addTapeRow(CALC_STATE.total, 'equals', true);

					}

				} else if (CALC_STATE.lastkey == 'key_equals') {

					if (CALC_STATE.lastMultTop == '*') {
						CALC_STATE.subtotal = executeOp(CALC_STATE.multiplier, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
						addTapeRow(CALC_STATE.multiplier, 'equals', true);
					} else {
				 		CALC_STATE.subtotal = executeOp(CALC_STATE.curval, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
				 		addTapeRow(CALC_STATE.curval, 'equals', true);
				 	}

				} else {

					if (CALC_STATE.lastkey != 'key_percent') {
						CALC_STATE.subtotal = executeOp(CALC_STATE.curval, CALC_STATE.lastMultTop, CALC_STATE.subtotal);
						addTapeRow(CALC_STATE.curval, 'equals', true);
					}
					
					if (CALC_STATE.lastop == '/') {
						CALC_STATE.divider = CALC_STATE.curval;
					}

				}

			}

			CALC_STATE.display = numberToString(CALC_STATE.subtotal);
			addTapeRow(CALC_STATE.subtotal, 'total', false);

			break;

		
		case 'key_total':
			
			CALC_STATE.display = numberToString(CALC_STATE.total);
			CALC_STATE.curval = CALC_STATE.total;
			// CALC_STATE.total = 0;
			
			CALC_STATE.lastMultTop = null;
			CALC_STATE.lastop = '=';

			if (CALC_STATE.lastkey == 'key_total') {
				CALC_STATE.display = '0';
				CALC_STATE.curval = 0;
				CALC_STATE.total = 0;
				CALC_STATE.lastMultTop = null;
				CALC_STATE.subtotal = null;
				CALC_STATE.lastop = null;

				addTapeRow(0, 'total', false);

			} else {
				addTapeRow(CALC_STATE.total, 'total', false);
			}

			break;

		case 'key_clear':

			CALC_STATE.display = '0';
			CALC_STATE.curval = 0;
			
			if (CALC_STATE.lastkey == 'key_equals') {
				CALC_STATE.lastMultTop = null;
			}
			
			if (CALC_STATE.lastkey == 'key_clear' || 
				CALC_STATE.lastkey == 'key_plus' ||
				CALC_STATE.lastkey == 'key_minus' ||
				CALC_STATE.lastkey == 'key_times' ||
				CALC_STATE.lastkey == 'key_divide' ||
				CALC_STATE.lastkey == 'key_total') {

				if (CALC_STATE.lastkey == 'key_clear') clearTape();
				CALC_STATE.total = 0;
				addTapeRow(CALC_STATE.total, 'total', false);
				CALC_STATE.lastMultTop = null;
				CALC_STATE.subtotal = null;
				CALC_STATE.lastop = null;
			}
		
	}

	CALC_STATE.lastkey = myButtonData.name;

	if (debug) {
		console.debug('after operation:');
		console.debug(JSON.stringify(CALC_STATE, null, 4));
	}
	
	updateDisplay();

	return;

}

function executeOp(num, op, total) {
	switch(op) {
		case '*': return total * num;
		case '/': return total / num;
	}
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

	$('#readout').html('<div class="inner">'+addThousandSeparators(CALC_STATE.display)+'</div>');

}

// put in thousand separators
function addThousandSeparators(aNumberInHtml) {

	var decimals = (aNumberInHtml.indexOf('.') > -1);
	var currentDigit = 0;
	var currentString = '';

	for (var i = aNumberInHtml.length - 1; i >= 0; i--) {

		var myChar = aNumberInHtml[i];
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

	aNumberInHtml = currentString.replace(/^([-]?)<span[^<]*<\/span>/, function(rep1, rep2) {
		return rep2;
	}); // <- rip any initial thousand separators

	return aNumberInHtml;

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
	else if (myType == '%') {
		myType = 'percent';
	}

	var myRow = $('<div class="row"></div>');

	myRow.addClass(myType);

	// TODO thousand separators
	// var v = aValue ? addThousandSeparators(numberToString(aValue, abbreviate)) : (aValue === null ? '0' : aValue);
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
	else if (myType == 'percent') {
		v += ' <span class="small-percent">%</span>';
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
		console.assert(CALC_STATE.subtotal == 8);
		if (CALC_STATE.subtotal != 8) return;

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
		console.assert(CALC_STATE.subtotal == 76);
		if (CALC_STATE.subtotal != 76) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus', 'key_4', 'key_times',
			'key_5', 'key_plus', 'key_5', 'key_plus', 'key_5', 'key_plus',
			 'key_equals'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 68);
		if (CALC_STATE.subtotal != 68) return;

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
		console.assert(CALC_STATE.subtotal == 8);
		if (CALC_STATE.subtotal != 8) return;

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
			'key_1', 'key_5', 'key_times',
			'key_times',
			'key_plus',
			'key_2', 'key_plus',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 227);
		if (CALC_STATE.total != 227) return;

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
			'key_1', 'key_2', 'key_5', 'key_0', 'key_times',
			'key_2', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 2500);
		if (CALC_STATE.subtotal != 2500) return;

		CALC_STATE.emulateKeyPressQueue = [
			'key_1', 'key_4', 'key_0', 'key_0', 'key_divide',
			'key_2', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 700);
		if (CALC_STATE.subtotal != 700) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_5', 'key_times',
			'key_1', 'key_5', 'key_plus',
			'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 225);
		if (CALC_STATE.subtotal != 225) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_2', 'key_5', 'key_0', 'key_times',
			'key_2', 'key_equals',
			'key_clear',
			'key_1', 'key_5', 'key_0', 'key_0', 'key_divide',
			'key_2', 'key_equals',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 750);
		if (CALC_STATE.subtotal != 750) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_5', 'key_times', 'key_5', 'key_equals',
			'key_total',
			'key_7', 'key_times', 'key_1', 'key_2', 'key_equals',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 84);
		if (CALC_STATE.subtotal != 84) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_5', 'key_times', 'key_5', 'key_times',
			'key_plus',
			'key_plus',
			'key_divide',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 750);
		if (CALC_STATE.subtotal != 750) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_5', 'key_times',
			'key_4', 'key_plus',
			'key_2',
			'key_equals',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 30);
		if (CALC_STATE.subtotal != 30) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_6', 'key_6', 'key_6',
			'key_plus', 'key_5',
			'key_plus', 'key_plus',
			'key_plus', 'key_minus',
			'key_plus', 'key_times',
			'key_plus', 'key_divide',
			'key_plus', 'key_equals',
			'key_plus', 'key_total'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 928884.9985337243);
		if (CALC_STATE.total != 928884.9985337243) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_0', 'key_period', 'key_6', 'key_6', 'key_6',
			'key_times', 'key_5',
			'key_times', 'key_plus',
			'key_times', 'key_minus',
			'key_times', 'key_times',
			'key_times', 'key_divide',
			'key_times', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 40187.3237092606);
		if (CALC_STATE.subtotal != 40187.3237092606) return;

		CALC_STATE.emulateKeyPressQueue = [
			'key_times', 'key_total',
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == -7.758900000000001);
		if (CALC_STATE.total != -7.758900000000001) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_5', 'key_plus', 'key_5', 'key_plus',
			'key_clear', 'key_5', 'key_plus'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 5);
		if (CALC_STATE.total != 5) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_0', 'key_0', 'key_0', 'key_divide',
			'key_2', 'key_divide',
			'key_5',
			'key_equals', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 20);
		if (CALC_STATE.subtotal != 20) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_0', 'key_0', 'key_0', 'key_divide',
			'key_2', 'key_divide',
			'key_5', 'key_divide',
			'key_equals', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 4);
		if (CALC_STATE.subtotal != 4) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_times', 'key_5', 'key_times',
			'key_plus', 'key_plus', 'key_plus'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 20);
		if (CALC_STATE.total != 20) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_times', 'key_5', 'key_equals',
			'key_plus', 'key_plus', 'key_plus'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.total == 30);
		if (CALC_STATE.total != 30) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_5', 'key_times', 'key_4', 'key_equals',
			'key_plus', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 100);
		if (CALC_STATE.subtotal != 100) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_5', 'key_times', 'key_2', 'key_equals',
			'key_equals', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 250);
		if (CALC_STATE.subtotal != 250) return;

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
		console.assert(CALC_STATE.total == -707.8857142857142);
		if (CALC_STATE.total != -707.8857142857142) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_1', 'key_0', 'key_0', 'key_0', 'key_divide',
			'key_2', 'key_divide',
			'key_5', 'key_equals',
			'key_times', 'key_3', 'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 300);
		if (CALC_STATE.subtotal != 300) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus',
			'key_3', 'key_times',
			'key_4', 'key_plus',
			'key_4', 'key_divide',
			'key_3', 'key_plus',
			'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 1.3333333333333333);
		if (CALC_STATE.subtotal != 1.3333333333333333) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_8', 'key_divide',
			'key_4', 'key_plus',
			'key_2', 'key_plus',
			'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 1.3333333333333333);
		if (CALC_STATE.subtotal != 1.3333333333333333) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus',
			'key_7', 'key_divide',
			'key_3', 'key_plus',
			'key_2', 'key_plus',
			'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 1);
		if (CALC_STATE.subtotal != 1) return;

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear',
			'key_2', 'key_plus',
			'key_7', 'key_divide',
			'key_3', 'key_plus',
			'key_2',
			'key_equals'
			];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.assert(CALC_STATE.subtotal == 3.5);
		if (CALC_STATE.subtotal != 3.5) return;


		/**

		7 / 3.5 = + =         	(0.57)
		7 / 3.5 = + + =         (1.14)



		2 *
		3
		=
		+
		4
		+
		(10)



		2 *
		3
		=
		+
		4
		=
		8



		printing test
		12 +
		23 +
		45 -
		34 *
		34 +
		23 /
		=

		45 +
		t

		34 /
		45 *
		=

		+

		34 +
		t

		c

		45 +
		t
		t

		**/

		CALC_STATE.emulateKeyPressQueue = ['key_clear', 'key_clear'];
		while (CALC_STATE.emulateKeyPressQueue.length) emulateKeyPress(null);
		console.warn('ALL TESTS PASSED');

	}, 500);
}

