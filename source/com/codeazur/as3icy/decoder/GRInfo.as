package com.codeazur.as3icy.decoder
{
	public class GRInfo
	{
		public var part2_3_length:int = 0;
		public var big_values:int = 0;
		public var global_gain:int = 0;
		public var scalefac_compress:int = 0;
		public var window_switching_flag:int = 0;
		public var block_type:int = 0;
		public var mixed_block_flag:int = 0;
		public var table_select:Vector.<int>;
		public var subblock_gain:Vector.<int>;
		public var region0_count:int = 0;
		public var region1_count:int = 0;
		public var preflag:int = 0;
		public var scalefac_scale:int = 0;
		public var count1table_select:int = 0;

		public function GRInfo()
		{
			table_select = new Vector.<int>(3, true);
			subblock_gain = new Vector.<int>(3, true);
		}
	}
}
