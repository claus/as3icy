package com.codeazur.as3icy.decoder
{
	import com.codeazur.as3icy.data.MPEGFrame;
	
	import flash.utils.ByteArray;
	
	public class Decoder
	{
		protected var l3decoder:LayerIIIDecoder;
		
		protected var output:OutputBuffer;
		
		public function Decoder(output_buffer:OutputBuffer) {
			output = output_buffer;
		}
		
		public function get outputBuffer():OutputBuffer {
			return output
		}
		
		public function decodeFrame(frame:MPEGFrame):void {
			retrieveDecoder(frame).decodeFrame(frame);
		}
		
		protected function retrieveDecoder(frame:MPEGFrame):IFrameDecoder {
			var decoder:IFrameDecoder;
			switch(frame.layer) {
				case MPEGFrame.MPEG_LAYER_III:
					if (l3decoder == null) {
						l3decoder = new LayerIIIDecoder(output);
					}
					decoder = l3decoder;
					break;
				default:
					throw(new Error("Unsupported MPEG Layer: " + frame.layer));
			}
			return decoder;
		}
	}
}
