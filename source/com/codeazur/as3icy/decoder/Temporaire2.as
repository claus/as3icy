package com.codeazur.as3icy.decoder
{
	import com.codeazur.as3icy.decoder.etc.VectorInt2D;
	
	public class Temporaire2
	{
		public var l:Vector.<int>;
		public var s:Vector.<Vector.<int>>;
		
		public function Temporaire2()
		{
			l = new Vector.<int>(23, true);
			s = (new VectorInt2D(3, 13)).v;
		}
	}
}
