package com.aupeo.as3icy.events 
{
	import flash.events.Event;
	
	public class ICYMetaDataEvent extends Event
	{
		public static const METADATA:String = "icyMetaData";

		protected var _metaData:String;
		
		public function ICYMetaDataEvent(eventType:String, aMetaData:String = "", bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(eventType, bubbles, cancelable);
			_metaData = aMetaData;
		}
		
		public function get metaData():String {
			return _metaData;
		}
		
		override public function toString():String {
			return "[ICYMetaDataEvent metaData=" + metaData + "]";
		}

		override public function clone():Event {
			return new ICYMetaDataEvent(type, metaData, bubbles, cancelable);
		}
	}
	
}