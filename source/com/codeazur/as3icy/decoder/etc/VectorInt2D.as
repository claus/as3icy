package com.codeazur.as3icy.decoder.etc
{
	public class VectorInt2D
	{
		public var v:Vector.<Vector.<int>>;
		
		public function VectorInt2D(level0Size:uint, level1Size:int = -1)
		{
			var hasLevel1Size:Boolean = (level1Size > -1);
			v = new Vector.<Vector.<int>>(level0Size, true);
			for (var i:uint = 0; i < level0Size; i++) {
				v[i] = new Vector.<int>(hasLevel1Size ? level1Size : 0, hasLevel1Size);
			}
		}
	}
}
