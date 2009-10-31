package com.codeazur.as3icy.decoder.etc
{
	public class VectorNumber3D
	{
		public var v:Vector.<Vector.<Vector.<Number>>>;
		
		public function VectorNumber3D(level0Size:uint, level1Size:uint, level2Size:uint)
		{
			v = new Vector.<Vector.<Vector.<Number>>>(level0Size, true);
			for (var i:uint = 0; i < level0Size; i++) {
				v[i] = new Vector.<Vector.<Number>>(level1Size, true);
				for (var j:uint = 0; j < level1Size; j++) {
					v[i][j] = new Vector.<Number>(level2Size, true);
				}
			}
		}
	}
}
