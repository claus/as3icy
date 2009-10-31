package com.codeazur.as3icy.decoder
{
	public class LayerIIISideInfo
	{
		public var main_data_begin:int = 0;
		public var private_bits:int = 0;
		public var ch:Vector.<Temporaire>;

		public function LayerIIISideInfo()
		{
			ch = new Vector.<Temporaire>(2, true);
			ch[0] = new Temporaire();
			ch[1] = new Temporaire();
		}
	}
}
