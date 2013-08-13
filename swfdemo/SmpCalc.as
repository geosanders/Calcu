package {
	
	//import com.greensock.*;
	//import com.greensock.easing.*;
	import flash.display.*;
	import flash.text.*;
	import flash.events.MouseEvent;
	
	public class SmpCalc extends MovieClip {
	
		const MODE_ADDITION = "addition";
		const MODE_SUBTRACTION = "subtraction";
		const MODE_DIVISION = "division";
		const MODE_MULTIPLICAITON = "multiplicaiton";

		public var calcMode:String = MODE_ADDITION;
		public var modeDisplay:String = "+";
		public var currentNum:String = "";
		public var total:Number = 0;
	
		public var btns:Array;
		public var btnTxt:Array;
		public var btnValue:Array;
		public var btnNames:Array;
		
		public function SmpCalc() {
			trace("init");

			calcInit();
			
		}
		
		public function calcInit() {
			trace("calcInit - " + calcInit);
		
			btns = new Array(calc.c0, calc.c1, calc.c2, calc.c3, calc.c4, calc.c5, calc.c6, calc.c7, calc.c8, calc.c9, calc.c_dec, calc.c_equal, calc.c_clear, calc.c_add, calc.c_sub, calc.c_mult, calc.c_divide, calc.c_mc, calc.c_mplus, calc.c_mminus, calc.c_mr);
			
			btnValue = new Array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, '.', '=', 'C', '+', '-', '*', '/', 'MC', 'M+', 'M-', 'MR');
			btnTxt = new Array(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, '.', '=', 'C', '+', '-', '*', '/', 'MC', 'M+', 'M-', 'MR');
			btnNames = new Array('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'dec', 'equal', 'clear', 'add', 'sub', 'mult', 'div', 'MC', 'M+', 'M-', 'MR');
			
			for (var i = 0; i < btns.length; i++) {
				var btn = btns[i];
				btn.val = btnValue[i];
				trace("btnValue[i] - " + btnValue[i]);
				// btn.name = btnNames[i];
				btn.txtHolder.txt.text = btnTxt[i].toString();
				
				if (btn.val is Number) {
					trace("btn.val - IS A NUMBER " + btn.val);
					btn.addEventListener(MouseEvent.CLICK, calculateMouseEvent);
				} else if (btn.val == "+")  {
					trace("btn.val - IS + " + btn.val);
					createTool(btn, MODE_ADDITION, btn.val);
				} else if (btn.val == '-')  {
					trace("btn.val - IS - " + btn.val);
					createTool(btn, MODE_SUBTRACTION, btn.val);
				} else if (btn.val == "*")  {
					trace("btn.val - IS * " + btn.val);
					createTool(btn, MODE_MULTIPLICAITON, btn.val);
				} else if (btn.val == "/")  {
					trace("btn.val - IS / " + btn.val);
					createTool(btn, MODE_DIVISION, btn.val);
				} else if (btn.val == "=")  {
					trace("btn.val - IS = " + btn.val);
					btn.addEventListener(MouseEvent.CLICK, equalsMouseEvent);
				} else if (btn.val == '.'){
					trace("btn.val - IS . " + btn.val);
					btn.addEventListener(MouseEvent.CLICK, calculateMouseEvent);
				} else if (btn.val == 'C'){
					trace("btn.val - IS Clear " + btn.val);
					btn.addEventListener(MouseEvent.CLICK, clearCalc);
				} else {
					trace("btn.val - IS OTHER " + btn.val);
				}
				trace("");
				
			}
		}
		
		function calculateMouseEvent(e:MouseEvent):void {
			currentNum += e.currentTarget.val.toString();
			calc.totalDisplay.text = total.toString() +" "+modeDisplay+" "+currentNum;
			// calc.totalDisplay.text = total.toString();
			// calc.totalDisplay.text += currentNum;
			// paperRoll.holder.txt.text += currentNum + " " + modeDisplay + "\r\r";
			// total.toString()
			return;
		}
		
		function createTool(mc:MovieClip, type:String, display:String) {
			mc.calcMode = type;
			mc.modeDisplay = display;
			mc.addEventListener(MouseEvent.CLICK, setModeMouseEvent);
			
		}

		function setModeMouseEvent(e:MouseEvent):void{
			calcMode = e.currentTarget.calcMode;
			modeDisplay = e.currentTarget.modeDisplay;
			if(currentNum!="")
				equalsMouseEvent();
			calc.totalDisplay.text = total.toString() + " " + modeDisplay ;
		}

		public function clearCalc(e:MouseEvent):void {
			calc.totalDisplay.text = 0;
			paperRoll.holder.txt.text += "/r/r 0"
		}

		function equalsMouseEvent(e:MouseEvent=null):void {
			var curNum:Number = parseFloat(currentNum);
			trace("curNum - " + curNum);
			
			paperRoll.holder.txt.text += curNum + " " + modeDisplay + "\r\r";
			
			switch(calcMode) {
				case MODE_ADDITION:
					total += curNum;
					break;
				case MODE_SUBTRACTION:
					total -= curNum;
					break;
				case MODE_DIVISION:
					total /= curNum;
					break;
				case MODE_MULTIPLICAITON:
					total *= curNum;
					break;
			}
			currentNum = "";
			calc.totalDisplay.text = total.toString();
		}
	}
}