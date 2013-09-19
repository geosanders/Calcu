

var ws;
var wsRetryHandle = 0;
var keyAnimHandle = 0;

function setupWebsocket() {

	wsRetryHandle = 0;

	if (typeof MozWebSocket != 'undefined') {
		ws = new MozWebSocket('ws://'+window.location.host+'/serial-relay');
	} else {
		ws = new WebSocket('ws://'+window.location.host+'/serial-relay');
	}

	// When the connection is open, send some data to the server
	ws.onopen = function () {
		console.log("Socket opened successfully")
	};

	// Log errors
	ws.onerror = function (error) {
	  console.log('WebSocket Error ' + error + ' (will retry shortly)');
	  if (wsRetryHandle) clearTimeout(wsRetryHandle);
	  wsRetryHandle = setTimeout(function() {
	  	setupWebsocket();
	  }, 3000);
	};

	ws.onclose = function() {
		console.log("Socket closed by server, will try again in 15 seconds...");
		if (wsRetryHandle) clearTimeout(wsRetryHandle);
	  	wsRetryHandle = setTimeout(function() {
			setupWebsocket();
		}, 15000);
	}

	// Log messages from the server
	ws.onmessage = function (e) {

		var d = JSON.parse(e.data);
		console.log("Got JSON data: ")
		console.log(d)

		// make sure we have a command
		if (d && d.c) {

			if (d.c == 'ready') {

				$('#readout_op').html('<div class="inner">'+''+'</div>');
				$('#readout').html('<div class="inner lcd">'+'...'+'</div>');

			}

			else if (d && d.c == 'lcdtxt') {

				$('#readout_op').html('<div class="inner">'+(d.d.length > 0 ? d.d.charAt(0) : '')+'</div>');
				$('#readout').html('<div class="inner lcd">'+(d.d.length > 0 ? d.d.substring(1) : d.d)+'</div>');

			}

			else if (d && d.c == 'key') {

				$('#key_'+d.d).addClass('down');

				if (keyAnimHandle) { clearTimeout(keyAnimHandle); }
				$('#key_'+d.d).addClass('down');
				keyAnimHandle = setTimeout(function() {
					$('.key').removeClass('down');
				}, 500)

			}

		}

		// var myData = (e.data+'').toLowerCase();
		// var myKeyName = getKeyNameFromSerialCode(myData);
		// if (myKeyName) {
		// 	console.log("Emulating key press: " + myKeyName);
		// 	emulateKeyPress(myKeyName);
		// }
		// else {
		// 	console.log("No key name could be found for serial code: " + myData);
		// }
		// // console.log('Ack back from server: ' + e.data);
	};

}

// startup stuff
$(function() {

	setupWebsocket();


	// clear the tape out
	clearTape();

});








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
};

/* map key combinations to buttons and data */
var KEY_DATA = {
	key_backspace: { keys:[{code:8,shift:0}], action: 'backspace' },
	key_clear: { keys:[{code:12,shift:1},{code:27,shift:0},{code:67,shift:0},{code:67,shift:1},{code:9,shift:0}], action: 'clear' },
	key_divide: { keys:[{code:111,shift:0},{code:191,shift:0}], action: 'setop', op:'/' },
	key_times: { keys:[{code:106,shift:0},{code:56,shift:1}], action: 'setop', op:'*' },
	key_minus: { keys:[{code:109,shift:0},{code:189,shift:0}], action: 'setop', op:'-' },
	key_plus: { keys:[{code:107,shift:0},{code:187,shift:1}], action: 'setop', op:'+' },
	key_equals: { keys:[{code:13,shift:0},{code:187,shift:0}], action: 'equals' },
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
		// CHANGED: now we just overwrite what the operator is
		else if (CALC_STATE.operator) {
			
			// _processCalcEquals();

			// var v = roundNumber(CALC_STATE.readout);

			// _processCalcEquals();

			// CALC_STATE.operands[1] = roundNumber(CALC_STATE.readout);
			// CALC_STATE.operands[0] = 0;
			// CALC_STATE.operator = myButtonData.op;
			// CALC_STATE.state = 'opsetwait';

			// just set
			CALC_STATE.operator = myButtonData.op;
			updateDisplay();
			return;

			// // push the value onto the operand stack
			// var v = roundNumber(CALC_STATE.readout);
			// CALC_STATE.operands[1] = v;
			// CALC_STATE.operands[0] = 0;
			// CALC_STATE.operator = myButtonData.op;
			// CALC_STATE.state = 'opsetwait';

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

$(function() {

	return

	// $('#main').hide().fadeIn();


	// var ws = new WebSocket('ws://'+window.location.host+'/main');
	// ws.onmessage = function(e) {
	// 	console.log(e.data);
	// };
	// // When the connection is open, send some data to the server
	// ws.onopen = function () {
	// 	ws.send(JSON.stringify({'action':'setDisplay','value':'0'}));
	// };

	// // Log errors
	// ws.onerror = function (errors) {
	//   console.log('WebSocket Error ' + error);
	// };

	// // Log messages from the server
	// ws.onmessage = function (e) {
	//   console.log('Ack back from server: ' + e.data);
	// };

	$(document).keydown(function(e) {
		console.log("Key down: " + e.keyCode);
		if (e.metaKey || e.altKey || e.ctrlKey) return; // don't mess with other hot keys
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
