package com.codeazur.as3icy.decoder
{
	public class SFTable
	{
		public var l:Vector.<int>;
		public var s:Vector.<int>;
		
		public function SFTable(thel:Vector.<int> = null, thes:Vector.<int> = null)
		{
			l = (thel != null) ? thel : new Vector.<int>(5, true);
			s = (thes != null) ? thes : new Vector.<int>(3, true);
		}
	}
}
