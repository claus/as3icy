package com.aupeo.as3icy.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class ICYFrameDataEvent extends Event
	{
		public static const FRAMEDATA:String = "icyFrameData";

		protected var _frameData:ByteArray;
		
		public function ICYFrameDataEvent(eventType:String, aFrameData:ByteArray, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(eventType, bubbles, cancelable);
			_frameData = aFrameData;
		}
		
		public function get frameData():ByteArray {
			return _frameData;
		}
		
		override public function toString():String {
			return "[ICYFrameDataEvent length=" + frameData.length + "]";
		}

		override public function clone():Event {
			return new ICYFrameDataEvent(type, frameData, bubbles, cancelable);
		}
	}
	
}