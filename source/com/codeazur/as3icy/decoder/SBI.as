package com.codeazur.as3icy.decoder
{
	public class SBI
	{
		public var l:Vector.<int>;
		public var s:Vector.<int>;
		
		public function SBI(thel:Vector.<int> = null, thes:Vector.<int> = null)
		{
			l = (thel != null) ? thel : new Vector.<int>(23, true);
			s = (thes != null) ? thes : new Vector.<int>(14, true);
		}
	}
}
