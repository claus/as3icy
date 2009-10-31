package com.codeazur.as3icy.decoder
{
	import com.codeazur.as3icy.data.MPEGFrame;
	
	public interface IFrameDecoder
	{
		function decodeFrame(frame:MPEGFrame):void;
	}
}
