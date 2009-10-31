package com.codeazur.as3icy.decoder
{
	/**
	* Implementation of Bit Reservoir for Layer III.
	* <p>
	* The implementation stores single bits as a word in the buffer. If
	* a bit is set, the corresponding word in the buffer will be non-zero.
	* If a bit is clear, the corresponding word is zero. Although this
	* may seem waseful, this can be a factor of two quicker than 
	* packing 8 bits to a byte and extracting. 
	* <p> 
	*/

	// REVIEW: there is no range checking, so buffer underflow or overflow
	// can silently occur.
	public class BitReserve
	{
		/**
		* Size of the internal buffer to store the reserved bits.
		* Must be a power of 2. And x8, as each bit is stored as a single
		* entry.
		*/
		protected static const BUFSIZE:uint = 4096 * 8;

		/**
		* Mask that can be used to quickly implement the
		* modulus operation on BUFSIZE.
		*/
		protected static const BUFSIZE_MASK:uint = BUFSIZE - 1;
		
		protected var offset:int;
		protected var totbit:int;
		protected var buf_byte_idx:int;
		protected var buf:Vector.<uint>;
		
		public function BitReserve()
		{
			buf = new Vector.<uint>(BUFSIZE, true);
			offset = 0;
			totbit = 0;
			buf_byte_idx = 0;	  
		}
		
		/**
		* Return totbit Field.
		*/
		public function get hsstell():int {
			return totbit;
		}
		
		/**
		* Read a number of bits from the bit stream.
		* @param n the number of
		*/
		public function hgetbits(n:int):int {
			totbit += n;
			var val:int = 0;
			var pos:int = buf_byte_idx;
			if (pos + n < BUFSIZE) {
				while (n-- > 0) {
					val <<= 1;
					if (buf[pos++] != 0) {
						val |= 1;
					}
				}
			} else {	 
				while (n-- > 0) {
					val <<= 1;
					if (buf[pos] != 0) {
						val |= 1;
					}
					pos = (pos + 1) & BUFSIZE_MASK;
				}
			}
			buf_byte_idx = pos;
			return val;
		}
		
		/**
		* Returns next bit from reserve.
		* @returns 0 if next bit is reset, or 1 if next bit is set.
		*/
		public function hget1bit():int {   	  
			totbit++;
			var val:int = buf[buf_byte_idx];
			buf_byte_idx = (buf_byte_idx + 1) & BUFSIZE_MASK;
			return val;
		}
		
		/**
		* Write 8 bits into the bit stream.
		*/
		public function hputbuf(val:int):void {   	  
			var ofs:int = offset;
			buf[ofs++] = val & 0x80;
			buf[ofs++] = val & 0x40;
			buf[ofs++] = val & 0x20;
			buf[ofs++] = val & 0x10;
			buf[ofs++] = val & 0x08;
			buf[ofs++] = val & 0x04;
			buf[ofs++] = val & 0x02;
			buf[ofs++] = val & 0x01;
			if (ofs == BUFSIZE) {
				offset = 0;
			} else {
				offset = ofs;
			}
		}
		
		/**
		* Rewind n bits in stream.
		*/
		public function rewindNbits(n:int):void {
			totbit -= n;
			buf_byte_idx -= n;
			if (buf_byte_idx < 0) {
				buf_byte_idx += BUFSIZE;
			}
		}
		
		/**
		* Rewind n bytes in stream.
		*/
		public function rewindNbytes(n:int):void {
			var bits:int = (n << 3);
			totbit -= bits;
			buf_byte_idx -= bits;	  
			if (buf_byte_idx < 0) {
				buf_byte_idx += BUFSIZE;
			}
		}
	}
}
