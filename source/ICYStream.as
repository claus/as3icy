package com.aupeo.as3icy 
{
	import com.aupeo.as3icy.events.ICYFrameDataEvent;
	import com.aupeo.as3icy.events.ICYMetaDataEvent;
	
	import com.aupeo.utils.StringUtils;

	import flash.events.*;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	public class ICYStream extends EventDispatcher
	{
		protected static var mpegBitrates:Array = 
		[
			[	
				[0, 32, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, -1],
				[0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, -1],
				[0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, -1]
			],[
				[0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, -1],
				[0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, -1],
				[0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, -1]
			]
		];
		protected static var mpegSamplingRates:Array = 
		[
			[44100, 48000, 32000],
			[22050, 24000, 16000],
			[11025, 12000, 8000]
		];
		
		protected var stream:URLStream;
		
		protected var _meta:String = "";
		protected var _framesLoaded:uint = 0;
		protected var _metaDataLoaded:uint = 0;
		protected var _metaDataBytesLoaded:uint = 0;

		protected var responseUrl:String = "";
		
		protected var _icyMetaSize:uint = 0;
		protected var _icyMetaInterval:uint = 0;
		protected var _icyName:String = "";
		protected var _icyDescription:String = "";
		protected var _icyUrl:String = "";
		protected var _icyGenre:String = "";
		protected var _icyBitrate:uint = 0;
		protected var _icyPublish:Boolean = false;
		protected var _icyServer:String = "";
		
		protected var _mpegVersion:uint;
		protected var _mpegLayer:uint;
		protected var _mpegHasCRC:Boolean;
		protected var _mpegCRC:uint;
		protected var _mpegBitrate:uint;
		protected var _mpegSamplingRate:uint;
		protected var _mpegPadding:Boolean;
		protected var _mpegChannelMode:uint;
		protected var _mpegChannelModeExt:uint;
		protected var _mpegCopyright:Boolean;
		protected var _mpegOriginal:Boolean;
		protected var _mpegEmphasis:uint;

		protected var readFunc:Function = readIdle;
		protected var readFuncContinue:Function;
		
		protected var icyHeader:ByteArray;
		protected var icyCRReceived:Boolean = false;
		protected var icyCRLFCount:uint = 0;

		protected var mpegFrameLength:uint;

		protected var read:uint = 0;
		protected var frameDataTmp:ByteArray;
		protected var frameCRCTmp:ByteArray;

		
		public function ICYStream() 
		{
			stream = new URLStream();
			stream.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			stream.addEventListener(ProgressEvent.PROGRESS, progressHandler);
		}
		
		
		public function load(request:URLRequest):void {
			read = 0;
			frameDataTmp = null;
			frameCRCTmp = null;
			icyHeader = null;
			icyCRReceived = false;
			icyCRLFCount = 0;
			_framesLoaded = 0;
			_metaDataLoaded = 0;
			_metaDataBytesLoaded = 0;
			responseUrl = request.url;
			stream.load(request);
		}
		
		public function close():void {
			stream.close();
		}
		

		public function get framesLoaded():uint { return _framesLoaded; }
		public function get metaDataLoaded():uint { return _metaDataLoaded; }
		public function get metaDataBytesLoaded():uint { return _metaDataBytesLoaded; }
		
		public function get icyMetaSize():uint { return _icyMetaSize; }
		public function get icyMetaInterval():uint { return _icyMetaInterval; }
		public function get icyName():String { return _icyName; }
		public function get icyDescription():String { return _icyDescription; }
		public function get icyUrl():String { return _icyUrl; }
		public function get icyGenre():String { return _icyGenre; }
		public function get icyBitrate():uint { return _icyBitrate; }
		public function get icyPublish():Boolean { return _icyPublish; }
		public function get icyServer():String { return _icyServer; }

		public function get mpegVersion():uint { return _mpegVersion; }
		public function get mpegLayer():uint { return _mpegLayer; }
		public function get mpegHasCRC():Boolean { return _mpegHasCRC; }
		public function get mpegCRC():uint { return _mpegCRC; }
		public function get mpegBitrate():uint { return _mpegBitrate; }
		public function get mpegSamplingRate():uint { return _mpegSamplingRate; }
		public function get mpegPadding():Boolean { return _mpegPadding; }
		public function get mpegChannelMode():uint { return _mpegChannelMode; }
		public function get mpegChannelModeExt():uint { return _mpegChannelModeExt; }
		public function get mpegCopyright():Boolean { return _mpegCopyright; }
		public function get mpegOriginal():Boolean { return _mpegOriginal; }
		public function get mpegEmphasis():uint { return _mpegEmphasis; }
		
		
		protected function set meta(value:String):void {
			_meta = value;
		}
		protected function get meta():String {
			return _meta;
		}
		

		protected function httpResponseStatusHandler(e:HTTPStatusEvent):void {
			if (e.responseHeaders.length > 0) {
				processResponseHeaders(e.responseHeaders);
				dispatchEvent(e.clone());
				readFunc = readFrameHeader0;
			} else {
				// no response headers probably means that we're dealing with
				// fucked up non-http ICY responses (ICY 200 OK), so we have to  
				// manually parse the headers
				responseUrl = e.responseURL;
				icyHeader = new ByteArray();
				readFunc = readNonHttpIcyHeaderOmgWtfLol;
			}
		}
		
		protected function progressHandler(e:ProgressEvent):void {
			if (readLoop()) {
				close();
			}
		}
		
		protected function readLoop():Boolean {
			while (readFunc());
			return (readFunc === readIdle);
		}
		
		protected function readIdle():Boolean {
			return false;
		}

		protected function readNonHttpIcyHeaderOmgWtfLol():Boolean {
			while (stream.bytesAvailable) {
				var b:uint = stream.readUnsignedByte();
				if (b == 0x0d) {
					icyCRReceived = true;
				} else if (b == 0x0a) {
					icyHeader.writeByte(b);
					icyCRLFCount++;
				} else {
					icyHeader.writeByte(b);
					icyCRReceived = false;
					icyCRLFCount = 0;
				}
				if (icyCRLFCount == 2) {
					icyHeader.position = 0;
					var responseHeaders:Array = [];
					var header:String = icyHeader.readUTFBytes(icyHeader.length);
					var items:Array = header.split(String.fromCharCode(0x0a));
					for (var i:uint = 0; i < items.length; i++) {
						var item:String = items[i];
						var j:int = item.indexOf(":");
						if (j > 0) {
							var name:String = StringUtils.trim(item.substring(0, j));
							var value:String = StringUtils.trim(item.substring(j + 1));
							responseHeaders.push(new URLRequestHeader(name, value));
						}
					}
					processResponseHeaders(responseHeaders);
					var e:HTTPStatusEvent = new HTTPStatusEvent(HTTPStatusEvent.HTTP_RESPONSE_STATUS, false, false, 200);
					e.responseHeaders = responseHeaders;
					e.responseURL = responseUrl;
					dispatchEvent(e);
					readFunc = readFrameHeader0;
					break;
				}
			}
			return true;
		}
		
		protected function readFrameHeader0():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0) {
					if (++read > icyMetaInterval) {
						readFuncContinue = readFrameHeader0;
						readFunc = readMetaDataSize;
						return ret;
					}
				}
				if (stream.readUnsignedByte() == 0xff) {
					readFunc = readFrameHeader1;
				} else {
					//trace("readFrameHeader0: no frame header");
				}
			} else {
				ret = false;
			}
			return ret;
		}
		
		protected function readFrameHeader1():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0) {
					if (++read > icyMetaInterval) {
						readFuncContinue = readFrameHeader1;
						readFunc = readMetaDataSize;
						return ret;
					}
				}
				var b:uint = stream.readUnsignedByte();
				if ((b & 0xe0) != 0xe0) {
					//trace("readFrameHeader1: no frame header");
					readFunc = readFrameHeader0;
					return ret;
				}
				// this appears to be a valid mpeg frame header, so proceed.
				// get the mpeg version
				// for now we only support mpeg 1.0
				var mpegVersionBits:uint = (b & 0x18) >> 3;
				if (mpegVersionBits == 3) {
					_mpegVersion = 1;
				} else {
					//trace("readFrameHeader1: unsupported mpeg version");
					readFunc = readFrameHeader0;
					return ret;
				}
				// get the mpeg layer version
				// for now we only support layer III
				var mpegLayerBits:uint = (b & 0x06) >> 1;
				if (mpegLayerBits == 1) {
					_mpegLayer = 3;
				} else {
					//trace("readFrameHeader1: unsupported mpeg layer");
					readFunc = readFrameHeader0;
					return ret;
				}
				// is the frame secured by crc?
				_mpegHasCRC = !((b & 0x01) != 0);
				// proceed with third header byte
				readFunc = readFrameHeader2;
			} else {
				ret = false;
			}
			return ret;
		}
		
		protected function readFrameHeader2():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0) {
					if (++read > icyMetaInterval) {
						readFuncContinue = readFrameHeader2;
						readFunc = readMetaDataSize;
						return ret;
					}
				}
				var b:uint = stream.readUnsignedByte();
				var bitrateIndex:uint = ((b & 0xf0) >> 4);
				// get the frame's bitrate
				if (bitrateIndex == 0 || bitrateIndex == 0xf0) {
					//trace("readFrameHeader2: unsupported bitrate index");
					readFunc = readFrameHeader0;
					return ret;
				}
				_mpegBitrate = mpegBitrates[mpegVersion - 1][mpegLayer - 1][bitrateIndex];
				// get the frame's samplingrate
				var samplingrateIndex:uint = ((b & 0x0c) >> 2);
				if (samplingrateIndex == 3) {
					//trace("readFrameHeader2: unsupported samplingrate index");
					readFunc = readFrameHeader0;
					return ret;
				}
				_mpegSamplingRate = mpegSamplingRates[mpegVersion - 1][samplingrateIndex];
				// is the frame padded?
				_mpegPadding = ((b & 0x02) == 0x02);
				// proceed with fourth and last header byte
				readFunc = readFrameHeader3;
			} else {
				ret = false;
			}
			return ret;
		}
		
		protected function readFrameHeader3():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0) {
					if (++read > icyMetaInterval) {
						readFuncContinue = readFrameHeader3;
						readFunc = readMetaDataSize;
						return ret;
					}
				}
				var b:uint = stream.readUnsignedByte();
				// get the frame's channel mode:
				// 0: stereo
				// 1: joint stereo
				// 2: dual channel
				// 3: mono
				_mpegChannelMode = ((b & 0xc0) >> 6);
				// get the frame's extended channel mode (only for joint stereo):
				_mpegChannelModeExt = ((b & 0x30) >> 4);
				// get the copyright flag
				_mpegCopyright = ((b & 0x08) == 0x08);
				// get the original flag
				_mpegOriginal = ((b & 0x04) == 0x04);
				// get the emphasis:
				// 0: none
				// 1: 50/15 ms
				// 2: reserved
				// 3: ccit j.17
				_mpegEmphasis = (b & 0x02);
				// almost done
				// calculate the frame length
				mpegFrameLength = Math.floor(((mpegVersion == 1) ? 144000 : 72000) * mpegBitrate / mpegSamplingRate) - 4;
				if (mpegPadding) {
					mpegFrameLength++;
				}
				// proceed with either the crc (if present) or the actual frame data
				readFunc = mpegCRC ? readCRC0 : readFrame;
			} else {
				ret = false;
			}
			return ret;
		}
		
		protected function readCRC0():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0) {
					if (++read >= icyMetaInterval) {
						readFuncContinue = readCRC0;
						readFunc = readMetaDataSize;
						return ret;
					}
				}
				frameCRCTmp = new ByteArray();
				stream.readBytes(frameCRCTmp, 0, 1);
				// proceed with the actual frame data
				readFunc = readCRC1;
			} else {
				ret = false;
			}
			return ret;
		}

		protected function readCRC1():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0) {
					if (++read >= icyMetaInterval) {
						readFuncContinue = readCRC1;
						readFunc = readMetaDataSize;
						return ret;
					}
				}
				stream.readBytes(frameCRCTmp, 1, 1);
				frameCRCTmp.position = 0;
				_mpegCRC = frameCRCTmp.readUnsignedShort();
				// CW:: TODO: not too sure about this.. 
				// CW:: TODO: does the frame length include header/crc or not? seems weird but also seems to work like this
				// CW:: TODO: see also readFrameHeader3(), i subtract 4 bytes (for the header) from the length there
				mpegFrameLength -= 2;
				// proceed with the actual frame data
				readFunc = readFrame;
			} else {
				ret = false;
			}
			return ret;
		}

		protected function readFrame():Boolean {
			var ret:Boolean = true;
			var len:uint = mpegFrameLength;
			var readTmp:uint = read;
			if (icyMetaInterval > 0) {
				if (frameDataTmp != null) {
					len -= frameDataTmp.length;
				}
				read += len;
				if (read >= icyMetaInterval) {
					len -= (read - icyMetaInterval);
				}
			}
			if (stream.bytesAvailable >= len) {
				var frameData:ByteArray = new ByteArray();
				if (icyMetaInterval > 0 && frameDataTmp != null) {
					stream.readBytes(frameDataTmp, frameDataTmp.length, len);
					frameData = frameDataTmp;
				} else {
					stream.readBytes(frameData, 0, len);
				}
				if (icyMetaInterval > 0 && read >= icyMetaInterval) {
					frameDataTmp = frameData;
					readFuncContinue = readFrame;
					readFunc = readMetaDataSize;
				} else {
					_framesLoaded++;
					frameDataTmp = null;
					dispatchEvent(new ICYFrameDataEvent(ICYFrameDataEvent.FRAMEDATA, frameData));
					readFunc = readFrameHeader0;
				}
			} else {
				read = readTmp;
				ret = false;
			}
			return ret;
		}
		
		protected function readMetaDataSize():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				read = 0;
				_icyMetaSize = (stream.readUnsignedByte() << 4);
				_metaDataBytesLoaded += _icyMetaSize + 1;
				_metaDataLoaded++;
				if (_icyMetaSize > 0) {
					readFunc = readMetaData;
				} else {
					dispatchEvent(new ICYMetaDataEvent(ICYMetaDataEvent.METADATA, meta));
					readFunc = readFuncContinue;
				}
			} else {
				ret = false;
			}
			return ret;
		}
			
		protected function readMetaData():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= _icyMetaSize) {
				read = 0;
				meta = stream.readUTFBytes(_icyMetaSize);
				dispatchEvent(new ICYMetaDataEvent(ICYMetaDataEvent.METADATA, meta));
				readFunc = readFuncContinue;
			} else {
				ret = false;
			}
			return ret;
		}

		
		protected function processResponseHeaders(headers:Array):void {
			for (var i:uint = 0; i < headers.length; i++) {
				var header:URLRequestHeader = headers[i] as URLRequestHeader;
				if (header) {
					switch(header.name) {
						case "icy-metaint": _icyMetaInterval = parseInt(header.value); break;
						case "icy-name": _icyName = header.value; break;
						case "icy-description": _icyDescription = header.value; break;
						case "icy-url": _icyUrl = header.value; break;
						case "icy-genre": _icyGenre = header.value; break;
						case "icy-br": _icyBitrate = parseInt(header.value); break;
						case "icy-pub": _icyPublish = (header.value == "1"); break;
						case "Server": _icyServer = header.value; break;
					}
				}
			}
		}
		
	}
	
}