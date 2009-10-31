package com.codeazur.as3icy.decoder
{
	import com.codeazur.as3icy.decoder.etc.VectorInt2D;
	
	public class Temporaire
	{
		public var scfsi:Vector.<int>;
		public var gr:Vector.<GRInfo>;
		
		public function Temporaire()
		{
			scfsi = new Vector.<int>(4, true);
			gr = new Vector.<GRInfo>(2, true);
			gr[0] = new GRInfo();
			gr[1] = new GRInfo();
		}
	}
}
