package com.aupeo.as3icy.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;

	import com.aupeo.as3icy.data.MPEGFrame;
	
	public class ICYFrameEvent extends Event
	{
		public static const FRAME:String = "icyFrame";

		protected var _frame:MPEGFrame;
		
		public function ICYFrameEvent(eventType:String, aFrame:MPEGFrame, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(eventType, bubbles, cancelable);
			_frame = aFrame;
		}
		
		public function get frame():MPEGFrame {
			return _frame;
		}
		
		override public function toString():String {
			return "[ICYFrameEvent frame=" + frame.toString() + "]";
		}

		override public function clone():Event {
			return new ICYFrameEvent(type, frame, bubbles, cancelable);
		}
	}
	
}