package com.codeazur.as3icy.decoder.etc
{
	public class VectorNumber2D
	{
		public var v:Vector.<Vector.<Number>>;
		
		public function VectorNumber2D(level0Size:uint, level1Size:uint)
		{
			v = new Vector.<Vector.<Number>>(level0Size, true);
			for (var i:uint = 0; i < level0Size; i++) {
				v[i] = new Vector.<Number>(level1Size, true);
			}
		}
	}
}
