
/* state of the calculator, set initially by a key_clear */
var CALC_STATE = {
	operator: null, // the current operator: / * - +
	operands: [0], // the operand stack
	readout: '0', // the currently in the readout
	justCleared: false, // flag to indicate if we just cleared
	keyPressed: null, // set to the textual code for the key currently pressed
	state: 'input', // current state:
					//   input (normal mode)
					//   opsetwait (after you set an operator the first time and next key is new number)
					//   postcalc (after a calculation has been made and it's showing the result number)
	emulateKeyPressQueue: [], // queue of key presses to emulate
};

/* map key combinations to buttons and data */
var KEY_DATA = {
	// NOTES: "*" key acts like CE if pressed once and then fully clears if pressed again, with some funky edge cases
	// CE specifically only deletes the current entry but the prior result is still there
	key_backspace: { keys:[{code:8,shift:0}], action: 'backspace', serialCode: 'bs' },
	key_clear: { keys:[{code:12,shift:1},{code:27,shift:0}], action: 'clear', serialCode: 'ce' },
	key_divide: { keys:[{code:111,shift:0},{code:191,shift:0}], action: 'setop', op:'/', serialCode: 'div' },
	key_times: { keys:[{code:106,shift:0}], action: 'setop', op:'*', serialCode: 'mul' },
	key_minus: { keys:[{code:109,shift:0}], action: 'setop', op:'-', serialCode: '-' },
	//key_plus: { keys:[{code:107,shift:0}], action: 'setop', op:'+', serialCode: '+' }, // on this device the + and = are the same key
	key_plus: { keys:[{code:107,shift:0}], action: 'setop', op:'+', serialCode: '+' },
	key_equals: { keys:[{code:13,shift:0}], action: 'equals', serialCode: '=' },
	key_period: { keys:[{code:110,shift:0},{code:190,shift:0}], action: 'append', item:'.', serialCode: '.' },
	key_00: { keys:[{code:96,shift:0},{code:48,shift:0}], action: 'append', item: '00', serialCode: '00' },
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
		setTimeout(function() {
			keyStateUp(myNext);
		}, 400);
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
	console.log(myButtonData);

	if (myButtonData.action == 'append') {

		CALC_STATE.justCleared = false;

		if (CALC_STATE.state == 'opsetwait' || CALC_STATE.state == 'postcalc') {
			CALC_STATE.readout = '0';
			CALC_STATE.state = 'input';
		}

		var r = CALC_STATE.readout;
		if (r == '0') {
			r = myButtonData.item;
		}
		else {

			// handle period separately
			if (myButtonData.item == '.') {
				// can't add two periods to a number
				if (r.indexOf('.') < 0) {
					r += myButtonData.item;
				}
			}

			// otherwise just append
			else {
				r += myButtonData.item;
			}
		}
		// discard this change if it's now too long
		if (r.length < 12) {
			CALC_STATE.readout = r;
		}
	}
	else if (myButtonData.action == 'backspace') {

		CALC_STATE.justCleared = false;

		if (CALC_STATE.state == 'opsetwait') {
			CALC_STATE.readout = '0';
			CALC_STATE.state = 'input';
		}

		var r = CALC_STATE.readout;
		if (r.length > 1) {
			r = r.substring(0, r.length-1);
		}
		else {
			r = '0';
		}
		CALC_STATE.readout = r;
	}
	else if (myButtonData.action == 'clear') {
		CALC_STATE.operator = null;
		CALC_STATE.operands = [0];
		CALC_STATE.readout = '0';
		CALC_STATE.state = 'input';

		// if this is the second time it's being cleared, we clear the tape too
		if (CALC_STATE.justCleared) {
			clearTape();
		}

		CALC_STATE.justCleared = true;

	}
	else if (myButtonData.action == 'setop') {

		CALC_STATE.justCleared = false;


		console.log(CALC_STATE.state);

		// if op not set or in postcalc state then we do the opsetwait thing
		if (!CALC_STATE.operator || CALC_STATE.state == 'postcalc') {

			var myPriorState = CALC_STATE.state;

			// push the value onto the operand stack
			var v = roundNumber(CALC_STATE.readout);
			CALC_STATE.operands[1] = v;
			CALC_STATE.operands[0] = 0;
			CALC_STATE.operator = myButtonData.op;
			CALC_STATE.state = 'opsetwait';

			// in postcalc we don't output the prior result
			if (myPriorState != 'postcalc') {
				addTapeRow(v, 'regular');
			}

		}

		// if the operator was already set, then we treat it like an equals
		else if (CALC_STATE.operator) {
			
			_processCalcEquals();

			// var v = roundNumber(CALC_STATE.readout);

			// _processCalcEquals();

			// CALC_STATE.operands[1] = roundNumber(CALC_STATE.readout);
			// CALC_STATE.operands[0] = 0;
			// CALC_STATE.operator = myButtonData.op;
			// CALC_STATE.state = 'opsetwait';

			// push the value onto the operand stack
			var v = roundNumber(CALC_STATE.readout);
			CALC_STATE.operands[1] = v;
			CALC_STATE.operands[0] = 0;
			CALC_STATE.operator = myButtonData.op;
			CALC_STATE.state = 'opsetwait';

		}

		else {
			console.log("setop called but we're in some odd unknown state, not doing anything...")
		}
	}
	

	if (myButtonData.action == 'equals') {

		CALC_STATE.justCleared = false;

		// only proceed if not in opsetwait mode and if there is an operator
		if (CALC_STATE.state == 'input' && CALC_STATE.operator) {
			_processCalcEquals();
		}

	}

	// update the last operand
	CALC_STATE.operands[0] = roundNumber(CALC_STATE.readout);

	updateDisplay();

}

/** helper called from processButtonPress() */
function _processCalcEquals() {

	var myOperator = CALC_STATE.operator;
	addTapeRow(CALC_STATE.operands[0], myOperator);

	var v = null;

	console.log("Doing calculation: " + CALC_STATE.operator);
	if (CALC_STATE.operator == '+') {
		v = roundNumber(CALC_STATE.operands[1] + CALC_STATE.operands[0]);
	}
	else if (CALC_STATE.operator == '-') {
		v = roundNumber(CALC_STATE.operands[1] - CALC_STATE.operands[0]);
	}
	else if (CALC_STATE.operator == '/') {
		v = roundNumber(CALC_STATE.operands[1] / CALC_STATE.operands[0]);
	}
	else if (CALC_STATE.operator == '*') {
		v = roundNumber(CALC_STATE.operands[1] * CALC_STATE.operands[0]);
	}
	console.log("Result of calculation is " + v);

	CALC_STATE.operands = [v];
	CALC_STATE.operator = null;
	CALC_STATE.state = 'postcalc';
	CALC_STATE.readout = numberToString(v);

	addTapeRow(null, 'separator');

	addTapeRow(v, 'total');

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

/** return number to two decimal places */
function roundNumber(v) {
	return parseFloat(parseFloat(v).toFixed(2));
}

/** return a user-friendly display of a number */
function numberToString(v) {

	var r = roundNumber(v)+'';
	if (r.match(/\.00/)) {
		r = r.substring(0, r.length-3);
	}
	else if (r.match(/\.[0-9]0/)) {
		r = r.substring(0, r.length-1);
	}

	return r;

}

/**
 * Add a row to the tape thing
 */
function addTapeRow(aValue, aType) {
	
	console.log("addTapeRow");

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

	var myRow = $('<div class="row"></div>');

	myRow.addClass(myType);

	var v = aValue ? numberToString(aValue) : aValue;

	if (myType == 'regular') {
		v += '&nbsp;&nbsp;&nbsp;';
	}
	else if (myType == 'total') {
		v += ' =';
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

	ws = new WebSocket('ws://'+window.location.host+'/serial-relay');

	// When the connection is open, send some data to the server
	ws.onopen = function () {
		console.log("Socket opened successfully")
	};

	// Log errors
	ws.onerror = function (error) {
	  console.log('WebSocket Error ' + error + ' (will retry shortly)');
	  setTimeout(function() {
	  	setupWebsocket();
	  }, 3000);
	};

	// Log messages from the server
	ws.onmessage = function (e) {
		var myData = (e.data+'').toLowerCase();
		var myKeyName = getKeyNameFromSerialCode(myData);
		if (myKeyName) {
			console.log("Emulating key press: " + myKeyName);
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
