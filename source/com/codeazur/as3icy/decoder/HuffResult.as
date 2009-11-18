package com.codeazur.as3icy.decoder
{
	public class HuffResult
	{
		public var x:int;
		public var y:int;
		public var v:int;
		public var w:int;
		
		public function HuffResult() {
			reset();
		}
		
		public function reset():void {
			x = 0;
			y = 0;
			v = 0;
			w = 0;
		}
	}
}
