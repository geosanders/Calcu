
/* state of the calculator, set initially by a key_clear */
var CALC_STATE = {
	operator: null, // the current operator: / * - +
	operands: [0], // the operand stack
	readout: '0', // the currently in the readout
	state: 'input', // current state:
					//   input (normal mode)
					//   opsetwait (after you set an operator the first time and next key is new number)
					//   postcalc (after a calculation has been made and it's showing the result number)
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

		if (CALC_STATE.state == 'opsetwait' || CALC_STATE.state == 'postcalc') {
			CALC_STATE.readout = '0';
			CALC_STATE.state = 'input';
		}

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
	else if (aButtonData.action == 'clear') {
		CALC_STATE.operator = null;
		CALC_STATE.operands = [0];
		CALC_STATE.readout = '0';
		CALC_STATE.state = 'input';

	}
	else if (aButtonData.action == 'setop') {
		// if not set then we do the opsetwait thing
		if (!CALC_STATE.operator || CALC_STATE.operator == 'postcalc') {
			// push the value onto the operand stack
			var v = roundNumber(CALC_STATE.readout);
			CALC_STATE.operands[1] = v;
			CALC_STATE.operands[0] = 0;
			CALC_STATE.operator = aButtonData.op;
			CALC_STATE.state = 'opsetwait';
		}
		// otherwise we just update what the operator is
		else {
			CALC_STATE.operator = aButtonData.op;
		}
	}
	else if (aButtonData.action == 'equals') {

		// only proceed if not in opsetwait mode and if there is an operator
		if (CALC_STATE.state == 'input' && CALC_STATE.operator) {

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

		}

	}
	else {
		console.log("unrecognized action: " + aButtonData.action);
	}

	// update the last operand
	CALC_STATE.operands[0] = roundNumber(CALC_STATE.readout);

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


$(function() {

	// $('#main').hide().fadeIn();

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
			keyStateUp(e.target.id);
		}
	});

	// clear everything out
	processButtonPress(KEY_DATA.key_clear);

	// do the initial display update
	updateDisplay();

});
