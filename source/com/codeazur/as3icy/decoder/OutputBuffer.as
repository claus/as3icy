package com.codeazur.as3icy.decoder
{
	public class OutputBuffer
	{
		public static const BUFFERSIZE:uint = 2 * 1152; // max. 2 * 1152 samples per frame
		public static const MAXCHANNELS:uint = 2; // max. number of channels

		protected var buffer:Vector.<Number>;
		protected var bufferp:Vector.<uint>;
		protected var channels:uint;
		protected var frequency:uint;

		public function OutputBuffer(sample_frequency:uint = 44100, number_of_channels:uint = 2)
		{
			buffer = new Vector.<Number>(BUFFERSIZE, true);
			bufferp = new Vector.<uint>(MAXCHANNELS, true);
			frequency = sample_frequency;
			channels = number_of_channels;
			clear_buffer();
		}

		public function getChannelCount():uint {
			return channels;  
		}

		public function getSampleFrequency():uint {
			return frequency;
		}

		public function getBuffer():Vector.<Number> {
			return buffer;  
		}

		public function getBufferLength():uint {
			return bufferp[0];
		}
  
		public function appendSamples(channel:uint, f:Vector.<Number>):void {
			var pos:uint = bufferp[channel];
			var fs:Number;
			for (var i:uint = 0; i < 32; ++i) {
				fs = f[i];
				fs = (fs > 1.0 ? 1.0 : (fs < -1.0 ? -1.0 : fs));
				buffer[pos] = fs;
				pos += channels;
			}
			bufferp[channel] = pos;
		}

		public function clear_buffer():void {
			for (var i:uint = 0; (i < channels) && (i < MAXCHANNELS); i++) {
				bufferp[i] = i;
			}
		}
	}
}
