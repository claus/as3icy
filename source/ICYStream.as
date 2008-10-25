package com.aupeo.as3icy 
{
	import com.aupeo.as3icy.data.MPEGFrame;
	import com.aupeo.as3icy.events.ICYFrameEvent;
	import com.aupeo.as3icy.events.ICYMetaDataEvent;
	
	import com.aupeo.utils.StringUtils;

	import flash.events.*;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	public class ICYStream extends EventDispatcher
	{
		protected var stream:URLStream;
		
		protected var _mpegFrame:MPEGFrame;
		
		protected var headerIndex:uint = 0;
		protected var crcIndex:uint = 0;
		
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
		
		protected var readFunc:Function = readIdle;
		protected var readFuncContinue:Function;
		
		protected var icyHeader:ByteArray;
		protected var icyCRReceived:Boolean = false;
		protected var icyCRLFCount:uint = 0;

		protected var read:uint = 0;
		protected var paused:Boolean = false;
		protected var frameDataTmp:ByteArray;

		
		public function ICYStream() 
		{
			stream = new URLStream();
			stream.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			stream.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			stream.addEventListener(Event.COMPLETE, completeHandler);
			stream.addEventListener(IOErrorEvent.IO_ERROR, defaultHandler);
			stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, defaultHandler);
			stream.addEventListener(HTTPStatusEvent.HTTP_STATUS, defaultHandler);
			stream.addEventListener(Event.OPEN, defaultHandler);
		}
		
		
		public function load(request:URLRequest):void {
			_mpegFrame = new MPEGFrame();
			read = 0;
			frameDataTmp = null;
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
		
		public function resume():void {
			if (paused && stream.connected) {
				paused = false;
				_mpegFrame = new MPEGFrame();
				readFunc = readFrameHeader;
				readLoop();
			}
		}
		

		public function get mpegFrame():MPEGFrame { return _mpegFrame; }
		
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
				readFunc = readFrameHeader;
			} else {
				// no response headers probably mean that we're dealing with
				// fucked up non-http ICY responses (ICY 200 OK), so we have to  
				// manually parse the headers. Well, ok then.
				responseUrl = e.responseURL;
				icyHeader = new ByteArray();
				readFunc = readNonHttpIcyHeaderOmgWtfLol;
			}
		}
		
		protected function completeHandler(e:Event):void {
			dispatchEvent(e.clone());
		}
		
		protected function progressHandler(e:ProgressEvent):void {
			dispatchEvent(e.clone());
			if (!paused && readLoop()) {
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
					readFunc = readFrameHeader;
					break;
				}
			}
			return true;
		}
		
		protected function readFrameHeader():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0 && ++read > icyMetaInterval) {
					readFuncContinue = readFrameHeader;
					readFunc = readMetaDataSize;
					return ret;
				}
				try {
					mpegFrame.setHeaderByteAt(headerIndex, stream.readUnsignedByte());
					if (++headerIndex == 4) {
						readFunc = mpegFrame.hasCRC ? readCRC : readFrame;
						headerIndex = 0;
					}
				}
				catch (e:Error) {
					//trace(e.message);
					headerIndex = 0;
				}
			} else {
				ret = false;
			}
			return ret;
		}
		
		protected function readCRC():Boolean {
			var ret:Boolean = true;
			if (stream.bytesAvailable >= 1) {
				if (icyMetaInterval > 0 && ++read > icyMetaInterval) {
					readFuncContinue = readCRC;
					readFunc = readMetaDataSize;
					return ret;
				}
				try {
					mpegFrame.setCRCByteAt(crcIndex, stream.readUnsignedByte());
					if (++crcIndex == 2) {
						readFunc = readFrame;
						crcIndex = 0;
					}
				}
				catch (e:Error) {
					//trace(e.message);
					readFunc = readFrameHeader;
					crcIndex = 0;
				}
			} else {
				ret = false;
			}
			return ret;
		}

		protected function readFrame():Boolean {
			var ret:Boolean = true;
			var readTmp:uint = read;
			var len:uint = mpegFrame.size;
			if (icyMetaInterval > 0) {
				if (frameDataTmp != null) {
					len -= frameDataTmp.length;
				}
				read += len;
				if (read >= icyMetaInterval) {
					len -= (read - icyMetaInterval);
					if (len == 0) {
						read = readTmp;
						frameDataTmp = frameData;
						readFuncContinue = readFrame;
						readFunc = readMetaDataSize;
						return ret;
					}
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
					mpegFrame.data = frameData;
					if (dispatchEvent(new ICYFrameEvent(ICYFrameEvent.FRAME, mpegFrame, false, true))) {
						_mpegFrame = new MPEGFrame();
						readFunc = readFrameHeader;
					} else {
						paused = true;
						ret = false;
					}
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
					dispatchEvent(new ICYMetaDataEvent(ICYMetaDataEvent.METADATA));
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
		
		protected function defaultHandler(e:Event):void {
			dispatchEvent(e.clone());
		}
	}
	
}