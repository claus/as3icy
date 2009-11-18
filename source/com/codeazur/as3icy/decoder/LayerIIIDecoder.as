package com.codeazur.as3icy.decoder
{
	import com.codeazur.as3icy.data.MPEGFrame;
	import com.codeazur.as3icy.decoder.etc.VectorInt2D;
	import com.codeazur.as3icy.decoder.etc.VectorNumber2D;
	import com.codeazur.as3icy.decoder.etc.VectorNumber3D;
	import com.codeazur.utils.BitArray;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class LayerIIIDecoder implements IFrameDecoder
	{
		protected var __c:uint = 0;
		
		protected static const SBLIMIT:uint = 32;
		protected static const SSLIMIT:uint = 18;

		public var scalefac_buffer:Vector.<int>;
		public var sftable:SFTable;
		
		protected var output:OutputBuffer;

		protected var checkSumHuff:int = 0;
		protected var is_1d:Vector.<int>;
		protected var ro:Vector.<Vector.<Vector.<Number>>>;
		protected var lr:Vector.<Vector.<Vector.<Number>>>;
		protected var out_1d:Vector.<Number>;
		protected var prevblck:Vector.<Vector.<Number>>;
		protected var k:Vector.<Vector.<Number>>;
		protected var nonzero:Vector.<int>;
		
		protected var br:BitReserve;
		protected var si:LayerIIISideInfo;
		
		protected var scalefac:Vector.<Temporaire2>;
		
		protected var max_gr:int;
		protected var frame_start:int;
		protected var part2_start:int;
		protected var channels:int;
		protected var first_channel:int;
		protected var last_channel:int;
		protected var sfreq:int;

		protected var sfBandIndex:Vector.<SBI>;
		protected var sfBandIndexCurrent:SBI;
		protected var reorder_table:Vector.<Vector.<int>>;
		
		protected var initialized:Boolean = false;
		
		protected var currentFrame:MPEGFrame;
		protected var currentFrameData:BitArray;
		protected var filter1:SynthesisFilter;
		protected var filter2:SynthesisFilter;

		protected var new_slen:Vector.<int>;
		protected var is_pos:Vector.<int>;
		protected var is_ratio:Vector.<Number>;
		protected var tsOutCopy:Vector.<Number>;
		protected var rawout:Vector.<Number>;
		protected var samples1:Vector.<Number>;
		protected var samples2:Vector.<Number>;
		protected var huffRes:HuffResult;
		
		
		public function LayerIIIDecoder(outputBuffer:OutputBuffer)
		{
			output = outputBuffer;
			new_slen = new Vector.<int>(4, true);
			is_pos = new Vector.<int>(576, true);
			is_ratio = new Vector.<Number>(576, true);
			tsOutCopy = new Vector.<Number>(18, true);
			rawout = new Vector.<Number>(36, true);
			samples1 = new Vector.<Number>(32, true);
			samples2 = new Vector.<Number>(32, true);
			huffRes = new HuffResult();
			filter1 = new SynthesisFilter(0);
			filter2 = new SynthesisFilter(1);
		}
		
		
		public function decodeFrame(frame:MPEGFrame):void
		{
			currentFrame = frame;
			currentFrameData = frame.data;
			
			if (!initialized) {
				initialize();
			}
			
			var t:int = getTimer();
			
			var nSlots:uint = frame.slots;
			var flush_main:int;
			var gr:int;
			var ch:int;
			var ss:int;
			var sb:int;
			var sb18:int;
			var main_data_end:int;
			var bytes_to_discard:int;
			var i:int;
			
			get_side_info();
			
			for (i = 0; i < nSlots; i++) {
				br.hputbuf(currentFrameData.readBits(8));
			}
			main_data_end = br.hsstell >>> 3; // of previous frame
			if ((flush_main = (br.hsstell & 7)) != 0) {
				br.hgetbits(8 - flush_main);
				main_data_end++;
			}
			bytes_to_discard = frame_start - main_data_end - si.main_data_begin;
			frame_start += nSlots;
			if (bytes_to_discard < 0) {
				return;
			}
			if (main_data_end > 4096) {
				frame_start -= 4096;
				br.rewindNbytes(4096);
			}
			for (; bytes_to_discard > 0; bytes_to_discard--) {
	    		br.hgetbits(8);
			}
			for (gr = 0; gr < max_gr; gr++)
			{
				for (ch = 0; ch < channels; ch++) {
					part2_start = br.hsstell;
					if (frame.version == MPEGFrame.MPEG_VERSION_1_0) {
						get_scale_factors(ch, gr);
					} else {
						get_lsf_scale_factors(ch, gr);
					}
					huffman_decode(ch, gr);
					dequantize_sample(ro[ch], ch, gr);
				}
				stereo(gr);
				//if ((which_channels == OutputChannels.DOWNMIX_CHANNELS) && (channels > 1)) {
				//	do_downmix();
				//}
				for (ch = first_channel; ch <= last_channel; ch++)
				{
					reorder(lr[ch], ch, gr);
					antialias(ch, gr);
					hybrid(ch, gr);
					for (sb18 = 18; sb18 < 576; sb18 += 36) {
						// Frequency inversion
						for (ss = 1; ss < SSLIMIT; ss += 2) {
							out_1d[sb18 + ss] = -out_1d[sb18 + ss];
						}
					}
					if (ch == 0) {
						for (ss = 0; ss < SSLIMIT; ss++) {
							 // Polyphase synthesis
							sb = 0;
							for (sb18 = 0; sb18 < 576; sb18 += 18) {
								samples1[sb++] = out_1d[sb18 + ss];
							}
							filter1.input_samples(samples1);
							filter1.calculate_pcm_samples(output);
						}
					} else {
						for (ss = 0; ss < SSLIMIT; ss++) {
							// Polyphase synthesis
							sb = 0;
							for (sb18 = 0; sb18 < 576; sb18 += 18) {
								samples2[sb++] = out_1d[sb18 + ss];
							}
							filter2.input_samples(samples2);
							filter2.calculate_pcm_samples(output);
						}
					}
				}
			}
			//trace((getTimer() - t) + "ms");
		}
		
		protected function get_side_info():Boolean
		{
			var ch:int;
			var gr:int;
			var gr_info:GRInfo;
			if (currentFrame.version == MPEGFrame.MPEG_VERSION_1_0) {
				si.main_data_begin = currentFrameData.readBits(9);
				if (channels == 1) {
					si.private_bits = currentFrameData.readBits(5);
				} else {
					si.private_bits = currentFrameData.readBits(3);
				}
				for (ch = 0; ch < channels; ch++) {
					si.ch[ch].scfsi[0] = currentFrameData.readBits(1);
					si.ch[ch].scfsi[1] = currentFrameData.readBits(1);
					si.ch[ch].scfsi[2] = currentFrameData.readBits(1);
					si.ch[ch].scfsi[3] = currentFrameData.readBits(1);
				}
				for (gr = 0; gr < 2; gr++) {
					for (ch = 0; ch < channels; ch++) {
						gr_info = si.ch[ch].gr[gr];
						gr_info.part2_3_length = currentFrameData.readBits(12);
						gr_info.big_values = currentFrameData.readBits(9);
						gr_info.global_gain = currentFrameData.readBits(8);
						gr_info.scalefac_compress = currentFrameData.readBits(4);
						gr_info.window_switching_flag = currentFrameData.readBits(1);
						if ((gr_info.window_switching_flag) != 0) {
							gr_info.block_type = currentFrameData.readBits(2);
							gr_info.mixed_block_flag = currentFrameData.readBits(1);
							gr_info.table_select[0] = currentFrameData.readBits(5);
							gr_info.table_select[1] = currentFrameData.readBits(5);
							gr_info.subblock_gain[0] = currentFrameData.readBits(3);
							gr_info.subblock_gain[1] = currentFrameData.readBits(3);
							gr_info.subblock_gain[2] = currentFrameData.readBits(3);
							// Set region_count parameters since they are implicit in this case.
							if (gr_info.block_type == 0) {
								// Side info bad: block_type == 0 in split block
								return false;
							} else if (gr_info.block_type == 2 && gr_info.mixed_block_flag == 0) {
								gr_info.region0_count = 8;
							} else {
								gr_info.region0_count = 7;
							}
							gr_info.region1_count = 20 - gr_info.region0_count;
						} else {
							gr_info.table_select[0] = currentFrameData.readBits(5);
							gr_info.table_select[1] = currentFrameData.readBits(5);
							gr_info.table_select[2] = currentFrameData.readBits(5);
							gr_info.region0_count = currentFrameData.readBits(4);
							gr_info.region1_count = currentFrameData.readBits(3);
							gr_info.block_type = 0;
						}
						gr_info.preflag = currentFrameData.readBits(1);
						gr_info.scalefac_scale = currentFrameData.readBits(1);
						gr_info.count1table_select = currentFrameData.readBits(1);
					}
				}
			} else {
				// MPEG-2 LSF, MPEG-2.5 LSF
				si.main_data_begin = currentFrameData.readBits(8);
				if (channels == 1) {
					si.private_bits = currentFrameData.readBits(1);
				} else {
					si.private_bits = currentFrameData.readBits(2);
				}
				for (ch = 0; ch < channels; ch++) {
					gr_info = si.ch[ch].gr[0];
					gr_info.part2_3_length = currentFrameData.readBits(12);
					gr_info.big_values = currentFrameData.readBits(9);
					gr_info.global_gain = currentFrameData.readBits(8);
					gr_info.scalefac_compress = currentFrameData.readBits(9);
					gr_info.window_switching_flag = currentFrameData.readBits(1);
					if ((gr_info.window_switching_flag) != 0) {
						gr_info.block_type = currentFrameData.readBits(2);
						gr_info.mixed_block_flag = currentFrameData.readBits(1);
						gr_info.table_select[0] = currentFrameData.readBits(5);
						gr_info.table_select[1] = currentFrameData.readBits(5);
						gr_info.subblock_gain[0] = currentFrameData.readBits(3);
						gr_info.subblock_gain[1] = currentFrameData.readBits(3);
						gr_info.subblock_gain[2] = currentFrameData.readBits(3);
						// Set region_count parameters since they are implicit in this case.
						if (gr_info.block_type == 0) {
							// Side info bad: block_type == 0 in split block
							return false;
						} else if (gr_info.block_type == 2 && gr_info.mixed_block_flag == 0) {
							gr_info.region0_count = 8;
						} else {
							gr_info.region0_count = 7;
							gr_info.region1_count = 20 - gr_info.region0_count;
						}
					} else {
						gr_info.table_select[0] = currentFrameData.readBits(5);
						gr_info.table_select[1] = currentFrameData.readBits(5);
						gr_info.table_select[2] = currentFrameData.readBits(5);
						gr_info.region0_count = currentFrameData.readBits(4);
						gr_info.region1_count = currentFrameData.readBits(3);
						gr_info.block_type = 0;
					}
					gr_info.scalefac_scale = currentFrameData.readBits(1);
					gr_info.count1table_select = currentFrameData.readBits(1);
				}
			}
			return true;
		}

		protected function get_scale_factors(ch:int, gr:int):void
		{
			var sfb:uint;
			var window:uint;
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			var s:Vector.<Vector.<int>> = scalefac[ch].s;
			var scale_comp:int = gr_info.scalefac_compress;
			var length0:int = slen[0][scale_comp];
			var length1:int = slen[1][scale_comp];
			if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2)) {
				if ((gr_info.mixed_block_flag) != 0) {
					// MIXED
					for (sfb = 0; sfb < 8; sfb++) {
						scalefac[ch].l[sfb] = br.hgetbits(slen[0][gr_info.scalefac_compress]);
					}
					for (sfb = 3; sfb < 6; sfb++) {
						for (window = 0; window < 3; window++) {
							s[window][sfb] = br.hgetbits(slen[0][gr_info.scalefac_compress]);
						}
					}
					for (sfb = 6; sfb < 12; sfb++) {
						for (window=0; window<3; window++) {
							s[window][sfb] = br.hgetbits(slen[1][gr_info.scalefac_compress]);
						}
					}
					for (sfb = 12, window = 0; window < 3; window++) {
						s[window][sfb] = 0;
					}
				} else {
					// SHORT
					s[0][0]  = br.hgetbits(length0);
					s[1][0]  = br.hgetbits(length0);
					s[2][0]  = br.hgetbits(length0);
					s[0][1]  = br.hgetbits(length0);
					s[1][1]  = br.hgetbits(length0);
					s[2][1]  = br.hgetbits(length0);
					s[0][2]  = br.hgetbits(length0);
					s[1][2]  = br.hgetbits(length0);
					s[2][2]  = br.hgetbits(length0);
					s[0][3]  = br.hgetbits(length0);
					s[1][3]  = br.hgetbits(length0);
					s[2][3]  = br.hgetbits(length0);
					s[0][4]  = br.hgetbits(length0);
					s[1][4]  = br.hgetbits(length0);
					s[2][4]  = br.hgetbits(length0);
					s[0][5]  = br.hgetbits(length0);
					s[1][5]  = br.hgetbits(length0);
					s[2][5]  = br.hgetbits(length0);
					s[0][6]  = br.hgetbits(length1);
					s[1][6]  = br.hgetbits(length1);
					s[2][6]  = br.hgetbits(length1);
					s[0][7]  = br.hgetbits(length1);
					s[1][7]  = br.hgetbits(length1);
					s[2][7]  = br.hgetbits(length1);
					s[0][8]  = br.hgetbits(length1);
					s[1][8]  = br.hgetbits(length1);
					s[2][8]  = br.hgetbits(length1);
					s[0][9]  = br.hgetbits(length1);
					s[1][9]  = br.hgetbits(length1);
					s[2][9]  = br.hgetbits(length1);
					s[0][10] = br.hgetbits(length1);
					s[1][10] = br.hgetbits(length1);
					s[2][10] = br.hgetbits(length1);
					s[0][11] = br.hgetbits(length1);
					s[1][11] = br.hgetbits(length1);
					s[2][11] = br.hgetbits(length1);
					s[0][12] = 0;
					s[1][12] = 0;
					s[2][12] = 0;
				}
			} else {
				// LONG types 0,1,3
				if ((si.ch[ch].scfsi[0] == 0) || (gr == 0)) {
					scalefac[ch].l[0]  = br.hgetbits(length0);
					scalefac[ch].l[1]  = br.hgetbits(length0);
					scalefac[ch].l[2]  = br.hgetbits(length0);
					scalefac[ch].l[3]  = br.hgetbits(length0);
					scalefac[ch].l[4]  = br.hgetbits(length0);
					scalefac[ch].l[5]  = br.hgetbits(length0);
				}
				if ((si.ch[ch].scfsi[1] == 0) || (gr == 0)) {
					scalefac[ch].l[6]  = br.hgetbits(length0);
					scalefac[ch].l[7]  = br.hgetbits(length0);
					scalefac[ch].l[8]  = br.hgetbits(length0);
					scalefac[ch].l[9]  = br.hgetbits(length0);
					scalefac[ch].l[10] = br.hgetbits(length0);
				}
				if ((si.ch[ch].scfsi[2] == 0) || (gr == 0)) {
					scalefac[ch].l[11] = br.hgetbits(length1);
					scalefac[ch].l[12] = br.hgetbits(length1);
					scalefac[ch].l[13] = br.hgetbits(length1);
					scalefac[ch].l[14] = br.hgetbits(length1);
					scalefac[ch].l[15] = br.hgetbits(length1);
				}
				if ((si.ch[ch].scfsi[3] == 0) || (gr == 0)) {
					scalefac[ch].l[16] = br.hgetbits(length1);
					scalefac[ch].l[17] = br.hgetbits(length1);
					scalefac[ch].l[18] = br.hgetbits(length1);
					scalefac[ch].l[19] = br.hgetbits(length1);
					scalefac[ch].l[20] = br.hgetbits(length1);
				}
				scalefac[ch].l[21] = 0;
				scalefac[ch].l[22] = 0;
			}
		}

		protected function get_lsf_scale_data(ch:int, gr:int):void
		{
			var scalefac_comp:int;
			var int_scalefac_comp:int;
			var mode_ext:int = currentFrame.channelModeExt;
			var m:int;
			var blocktypenumber:int;
			var blocknumber:int = 0;
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			scalefac_comp = gr_info.scalefac_compress;
			if (gr_info.block_type == 2) {
				if (gr_info.mixed_block_flag == 0) {
					blocktypenumber = 1;
				} else if (gr_info.mixed_block_flag == 1) {
					blocktypenumber = 2;
				} else {
					blocktypenumber = 0;
				}
			} else {
				blocktypenumber = 0;
			}
			if (!(((mode_ext == 1) || (mode_ext == 3)) && (ch == 1))) {
				if (scalefac_comp < 400) {
					new_slen[0] = (scalefac_comp >>> 4) / 5;
					new_slen[1] = (scalefac_comp >>> 4) % 5;
					new_slen[2] = (scalefac_comp & 0xF) >>> 2;
					new_slen[3] = (scalefac_comp & 3);
					si.ch[ch].gr[gr].preflag = 0;
					blocknumber = 0;
				} else if (scalefac_comp  < 500) {
					new_slen[0] = ((scalefac_comp - 400) >>> 2) / 5;
					new_slen[1] = ((scalefac_comp - 400) >>> 2) % 5;
					new_slen[2] = (scalefac_comp - 400 ) & 3;
					new_slen[3] = 0;
					si.ch[ch].gr[gr].preflag = 0;
					blocknumber = 1;
				} else if (scalefac_comp < 512) {
					new_slen[0] = (scalefac_comp - 500 ) / 3;
					new_slen[1] = (scalefac_comp - 500)  % 3;
					new_slen[2] = 0;
					new_slen[3] = 0;
					si.ch[ch].gr[gr].preflag = 1;
					blocknumber = 2;
				}
			}
			if ((((mode_ext == 1) || (mode_ext == 3)) && (ch == 1))) {
				int_scalefac_comp = scalefac_comp >>> 1;
				if (int_scalefac_comp < 180) {
					new_slen[0] = int_scalefac_comp / 36;
					new_slen[1] = (int_scalefac_comp % 36 ) / 6;
					new_slen[2] = (int_scalefac_comp % 36) % 6;
					new_slen[3] = 0;
					si.ch[ch].gr[gr].preflag = 0;
					blocknumber = 3;
				} else if (int_scalefac_comp < 244) {
					new_slen[0] = ((int_scalefac_comp - 180 )  & 0x3F) >>> 4;
					new_slen[1] = ((int_scalefac_comp - 180) & 0xF) >>> 2;
					new_slen[2] = (int_scalefac_comp - 180 ) & 3;
					new_slen[3] = 0;
					si.ch[ch].gr[gr].preflag = 0;
					blocknumber = 4;
				} else if (int_scalefac_comp < 255) {
					new_slen[0] = (int_scalefac_comp - 244 ) / 3;
					new_slen[1] = (int_scalefac_comp - 244 )  % 3;
					new_slen[2] = 0;
					new_slen[3] = 0;
					si.ch[ch].gr[gr].preflag = 0;
					blocknumber = 5;
				}
			}
			for (var x:int = 0; x < 45; x++) {
				 // why 45, not 54?
				 scalefac_buffer[x] = 0;
			}
			m = 0;
			for (var i:int = 0; i < 4; i++) {
				for (var j:int = 0; j < nr_of_sfb_block[blocknumber][blocktypenumber][i]; j++) {
					scalefac_buffer[m++] = (new_slen[i] == 0) ? 0 : br.hgetbits(new_slen[i]);
				}
			}
		}

		protected function get_lsf_scale_factors(ch:int, gr:int):void
		{
			var m:int = 0;
			var sfb:int;
			var window:int;
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			get_lsf_scale_data(ch, gr);
			if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2)) {
				if (gr_info.mixed_block_flag != 0) {
					// MIXED
					for (sfb = 0; sfb < 8; sfb++) {
						scalefac[ch].l[sfb] = scalefac_buffer[m++];
					}
					for (sfb = 3; sfb < 12; sfb++) {
						for (window = 0; window < 3; window++) {
							scalefac[ch].s[window][sfb] = scalefac_buffer[m++];
						}
					}
					for (window = 0; window < 3; window++) {
						scalefac[ch].s[window][12] = 0;
					}
				} else {
					// SHORT
					for (sfb = 0; sfb < 12; sfb++) {
						for (window = 0; window < 3; window++) {
							scalefac[ch].s[window][sfb] = scalefac_buffer[m++];
						}
					}
					for (window = 0; window < 3; window++) {
						scalefac[ch].s[window][12] = 0;
					}
				}
			} else {
				// LONG types 0,1,3
				for (sfb = 0; sfb < 21; sfb++) {
					scalefac[ch].l[sfb] = scalefac_buffer[m++];
				}
				scalefac[ch].l[21] = 0; // Jeff
				scalefac[ch].l[22] = 0;
			}
		}

		protected function huffman_decode(ch:int, gr:int):void
		{
			var part2_3_end:int = part2_start + si.ch[ch].gr[gr].part2_3_length;
			var num_bits:int;
			var region1Start:int;
			var region2Start:int;
			var index:int;
			var buf:int;
			var buf1:int;
			var h:HuffCodeTab;

			huffRes.reset();
			
			// Find region boundary for short block case
			if (((si.ch[ch].gr[gr].window_switching_flag) != 0) && (si.ch[ch].gr[gr].block_type == 2)) {
				// Region2.
				// MS: Extrahandling for 8KHZ
				region1Start = (sfreq == 8) ? 72 : 36;  // sfb[9 / 3] * 3 = 36 or in case 8KHZ = 72
				region2Start = 576; // No Region2 for short block case
			} else {
				// Find region boundary for long block case
				buf = si.ch[ch].gr[gr].region0_count + 1;
				buf1 = buf + si.ch[ch].gr[gr].region1_count + 1;
				if (buf1 > sfBandIndexCurrent.l.length - 1) {
					buf1 = sfBandIndexCurrent.l.length - 1;
				}
				region1Start = sfBandIndexCurrent.l[buf];
				region2Start = sfBandIndexCurrent.l[buf1]; /* MI */
			}
			
			index = 0;
			
			// Read bigvalues area
			var num:int = Math.min((si.ch[ch].gr[gr].big_values << 1), is_1d.length);
			for (var i:int = 0; i < num; i += 2) {
				if (i < region1Start) {
					h = HuffCodeTab.ht[si.ch[ch].gr[gr].table_select[0]];
				} else if (i < region2Start) {
					h = HuffCodeTab.ht[si.ch[ch].gr[gr].table_select[1]];
				} else {
					h = HuffCodeTab.ht[si.ch[ch].gr[gr].table_select[2]];
				}
				HuffCodeTab.huffman_decoder(h, huffRes, br);
				is_1d[index++] = huffRes.x;
				is_1d[index++] = huffRes.y;
				checkSumHuff = checkSumHuff + huffRes.x + huffRes.y;
			}
			
			// Read count1 area
			h = HuffCodeTab.ht[si.ch[ch].gr[gr].count1table_select + 32];
			num_bits = br.hsstell;
			while ((num_bits < part2_3_end) && (index < 576)) {
				HuffCodeTab.huffman_decoder(h, huffRes, br);
				is_1d[index++] = huffRes.v;
				is_1d[index++] = huffRes.w;
				is_1d[index++] = huffRes.x;
				is_1d[index++] = huffRes.y;
				checkSumHuff = checkSumHuff + huffRes.v + huffRes.w + huffRes.x + huffRes.y;
				num_bits = br.hsstell;
			}
			if (num_bits > part2_3_end) {
				br.rewindNbits(num_bits - part2_3_end);
				index -= 4;
			}
			num_bits = br.hsstell;
			
			// Dismiss stuffing bits
			if (num_bits < part2_3_end) {
				br.hgetbits(part2_3_end - num_bits);
			}
			
			// Zero out rest
			nonzero[ch] = (index < 576) ? index : 576;
			if (index < 0) {
				index = 0;
			}
			
			// may not be necessary
			for (; index < 576; index++) {
				is_1d[index] = 0;
			}
		}
		
		protected function i_stereo_k_values(is_pos:int, io_type:int, i:int):void
		{
			if (is_pos == 0) {
				k[0][i] = 1.0;
				k[1][i] = 1.0;
			} else if ((is_pos & 1) != 0) {
				k[0][i] = io[io_type][(is_pos + 1) >>> 1];
				k[1][i] = 1.0;
			} else {
				k[0][i] = 1.0;
				k[1][i] = io[io_type][is_pos >>> 1];
			}
		}

		protected function dequantize_sample(xr:Vector.<Vector.<Number>>, ch:int, gr:int):void
		{
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			var cb:int = 0;
			var next_cb_boundary:int;
			var cb_begin:int = 0;
			var cb_width:int = 0;
			var index:int = 0;
			var t_index:int;
			var j:int;
			var g_gain:Number;
			var xr_1d:Vector.<Vector.<Number>> = xr;

			var reste:int;
			var quotien:int;
			var idx:int;

			// Choose correct scalefactor band per block type, initalize boundary
			if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2)) {
				if (gr_info.mixed_block_flag != 0) {
					next_cb_boundary = sfBandIndexCurrent.l[1]; // LONG blocks: 0,1,3
				} else {
					cb_width = sfBandIndexCurrent.s[1];
					next_cb_boundary = (cb_width << 2) - cb_width;
					cb_begin = 0;
				}
			} else {
				next_cb_boundary = sfBandIndexCurrent.l[1]; // LONG blocks: 0,1,3
			}

			// Compute overall (global) scaling.
			g_gain = Math.pow(2.0, (0.25 * (gr_info.global_gain - 210.0)));
			for (j = 0; j < nonzero[ch]; j++) {
				reste = j % SSLIMIT;
				quotien = int((j - reste) / SSLIMIT);
				if (is_1d[j] == 0) {
					xr_1d[quotien][reste] = 0.0;
				} else {
					var abv:int = is_1d[j];
					// Pow Array fix (11/17/04)
					if (abv < t_43.length) {
						if (is_1d[j] > 0) {
							xr_1d[quotien][reste] = g_gain * t_43[abv];
						} else {
							if (-abv < t_43.length) {
								xr_1d[quotien][reste] = -g_gain * t_43[-abv];
							} else {
								xr_1d[quotien][reste] = -g_gain * Math.pow(-abv, d43);	
							}
						}
					} else {
						if (is_1d[j] > 0) {
							xr_1d[quotien][reste] = g_gain * Math.pow(abv, d43);
						} else {
							xr_1d[quotien][reste] = -g_gain * Math.pow(-abv, d43);	         	
						}
					}
				}
			}

			// Apply formula per block type
			for (j = 0; j < nonzero[ch]; j++) {
				reste = j % SSLIMIT;
				quotien = int((j - reste) / SSLIMIT);
				if (index == next_cb_boundary) { /* Adjust critical band boundary */
					if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2)) {
						if (gr_info.mixed_block_flag != 0) {
							if (index == sfBandIndexCurrent.l[8]) {
								next_cb_boundary = sfBandIndexCurrent.s[4];
								next_cb_boundary = (next_cb_boundary << 2) -
								next_cb_boundary;
								cb = 3;
								cb_width = sfBandIndexCurrent.s[4] - sfBandIndexCurrent.s[3];
								cb_begin = sfBandIndexCurrent.s[3];
								cb_begin = (cb_begin << 2) - cb_begin;
							} else if (index < sfBandIndexCurrent.l[8]) {
								next_cb_boundary = sfBandIndexCurrent.l[(++cb) + 1];
							} else {
								next_cb_boundary = sfBandIndexCurrent.s[(++cb) + 1];
								next_cb_boundary = (next_cb_boundary << 2) - next_cb_boundary;
								cb_begin = sfBandIndexCurrent.s[cb];
								cb_width = sfBandIndexCurrent.s[cb + 1] - cb_begin;
								cb_begin = (cb_begin << 2) - cb_begin;
							}
						} else {
							next_cb_boundary = sfBandIndexCurrent.s[(++cb) + 1];
							next_cb_boundary = (next_cb_boundary << 2) - next_cb_boundary;
							cb_begin = sfBandIndexCurrent.s[cb];
							cb_width = sfBandIndexCurrent.s[cb + 1] - cb_begin;
							cb_begin = (cb_begin << 2) - cb_begin;
						}
					} else  { // long blocks
						next_cb_boundary = sfBandIndexCurrent.l[(++cb) + 1];
					}
				}

				// Do long/short dependent scaling operations
				if ((gr_info.window_switching_flag != 0) &&
					(((gr_info.block_type == 2) && (gr_info.mixed_block_flag == 0)) ||
					 ((gr_info.block_type == 2) && (gr_info.mixed_block_flag != 0) && (j >= 36))))
				{
					t_index = (index - cb_begin) / cb_width;
					idx = scalefac[ch].s[t_index][cb] << gr_info.scalefac_scale;
					idx += (gr_info.subblock_gain[t_index] << 2);
					xr_1d[quotien][reste] *= two_to_negative_half_pow[idx];
				} else {
					// LONG block types 0,1,3 & 1st 2 subbands of switched blocks
					idx = scalefac[ch].l[cb];
					if (gr_info.preflag != 0) {
						idx += pretab[cb];
					}
					idx = (idx << gr_info.scalefac_scale);
					xr_1d[quotien][reste] *= two_to_negative_half_pow[idx];
				}
				index++;
			}

			for (j = nonzero[ch]; j < 576; j++) {
				reste = j % SSLIMIT;
				quotien = int((j - reste) / SSLIMIT);
				if (reste < 0) { reste = 0; }
				if(quotien < 0) { quotien = 0; }
				xr_1d[quotien][reste] = 0.0;
			}
		}
	
		protected function reorder(xr:Vector.<Vector.<Number>>, ch:int, gr:int):void
		{
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			var freq:int;
			var freq3:int;
			var index:int;
			var sfb:int;
			var sfb_start:int;
			var sfb_lines:int;
			var src_line:int;
			var des_line:int;
			var reste:int;
			var quotien:int;
			var xr_1d:Vector.<Vector.<Number>> = xr;
			if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2)) {
				for (index = 0; index < 576; index++) {
					out_1d[index] = 0.0;
				}
				if (gr_info.mixed_block_flag != 0) {
					// NO REORDER FOR LOW 2 SUBBANDS
					for (index = 0; index < 36; index++) {
						reste = index % SSLIMIT;
						quotien = int((index - reste) / SSLIMIT);
						out_1d[index] = xr_1d[quotien][reste];
					}
					// REORDERING FOR REST SWITCHED SHORT
					for (sfb = 3; sfb < 13; sfb++) {						   
						sfb_start = sfBandIndexCurrent.s[sfb];
						sfb_lines = sfBandIndexCurrent.s[sfb + 1] - sfb_start;
						var sfb_start3:int = (sfb_start << 2) - sfb_start;
						for (freq = 0, freq3 = 0; freq < sfb_lines; freq++, freq3 += 3) {
							src_line = sfb_start3 + freq;
							des_line = sfb_start3 + freq3;
							reste = src_line % SSLIMIT;
							quotien = int((src_line - reste) / SSLIMIT);
							out_1d[des_line] = xr_1d[quotien][reste];
							src_line += sfb_lines;
							des_line++;
							reste = src_line % SSLIMIT;
							quotien = int((src_line - reste) / SSLIMIT);
							out_1d[des_line] = xr_1d[quotien][reste];
							src_line += sfb_lines;
							des_line++;
							reste = src_line % SSLIMIT;
							quotien = int((src_line - reste) / SSLIMIT);
							out_1d[des_line] = xr_1d[quotien][reste];
						}
					}
				} else {
					// pure short
					for (index = 0; index < 576; index++) {
						var j:int = reorder_table[sfreq][index];
						reste = j % SSLIMIT;
						quotien = int((j - reste) / SSLIMIT);
						out_1d[index] = xr_1d[quotien][reste];
					}
				}
			} else {
				// long blocks
				for (index = 0; index < 576; index++) {
					reste = index % SSLIMIT;
					quotien = int((index - reste) / SSLIMIT);
					out_1d[index] = xr_1d[quotien][reste];
				}
			}
		}
		
		protected function stereo(gr:int):void
		{
			var sb:int;
			var ss:int;
			if (channels == 1) {
				// mono, bypass xr[0][][] to lr[0][][]
				for (sb = 0; sb < SBLIMIT; sb++) {
					for (ss = 0; ss < SSLIMIT; ss += 3) {
						lr[0][sb][ss]     = ro[0][sb][ss];
						lr[0][sb][ss + 1] = ro[0][sb][ss + 1];
						lr[0][sb][ss + 2] = ro[0][sb][ss + 2];
					}
				}
			} else {
				var gr_info:GRInfo = si.ch[0].gr[gr];
				var mode_ext:uint = currentFrame.channelModeExt;
				var sfb:int;
				var i:int;
				var j:uint;
				var sfbcnt:int;
				var lines:int;
				var temp:int;
				var temp2:int;
				var ms_stereo:Boolean = ((currentFrame.channelMode == MPEGFrame.CHANNEL_MODE_JOINT_STEREO) && ((mode_ext & 0x2) != 0));
				var i_stereo:Boolean = ((currentFrame.channelMode == MPEGFrame.CHANNEL_MODE_JOINT_STEREO) && ((mode_ext & 0x1) != 0));
				var lsf:Boolean = ((currentFrame.version == MPEGFrame.MPEG_VERSION_2_0) || (currentFrame.version == MPEGFrame.MPEG_VERSION_2_5));
				var io_type:int = (gr_info.scalefac_compress & 1);
				
				// Initialization
				for (i = 0; i < 576; i++) {
					is_pos[i] = 7;
					is_ratio[i] = 0.0;
				}
				if (i_stereo) {
					if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2)) {
						if (gr_info.mixed_block_flag != 0) {
							var max_sfb:int = 0;
							for (j = 0; j < 3; j++) {
								sfbcnt = 2;
								for (sfb = 12; sfb >= 3; sfb--) {
									i = sfBandIndexCurrent.s[sfb];
									lines = sfBandIndexCurrent.s[sfb + 1] - i;
									i = (i << 2) - i + (j + 1) * lines - 1;
									while (lines > 0) {
										if (ro[1][i / 18][i % 18] != 0.0) {
											sfbcnt = sfb;
											sfb = -10;
											lines = -10;
										}
										lines--;
										i--;
									}
								}
								sfb = sfbcnt + 1;
								if (sfb > max_sfb) {
									max_sfb = sfb;
								}
								while (sfb < 12) {
									temp = sfBandIndexCurrent.s[sfb];
									sb = sfBandIndexCurrent.s[sfb + 1] - temp;
									i = (temp << 2) - temp + j * sb;
									for (; sb > 0; sb--) {
										is_pos[i] = scalefac[1].s[j][sfb];
										if (is_pos[i] != 7) {
											if (lsf) {
												i_stereo_k_values(is_pos[i], io_type, i);
											} else {
												is_ratio[i] = TAN12[is_pos[i]];
											}
										}
										i++;
									}
									sfb++;
								}
								sfb = sfBandIndexCurrent.s[10];
								sb  = sfBandIndexCurrent.s[11] - sfb;
								sfb = (sfb << 2) - sfb + j * sb;
								temp  = sfBandIndexCurrent.s[11];
								sb = sfBandIndexCurrent.s[12] - temp;
								i = (temp << 2) - temp + j * sb;
								for (; sb > 0; sb--) {
									is_pos[i] = is_pos[sfb];
									if (lsf) {
										k[0][i] = k[0][sfb];
										k[1][i] = k[1][sfb];
									} else {
										is_ratio[i] = is_ratio[sfb];
									}
									i++;
								}
							}
							if (max_sfb <= 3) {
								i = 2;
								ss = 17;
								sb = -1;
								while (i >= 0) {
									if (ro[1][i][ss] != 0.0) {
										sb = (i << 4) + (i << 1) + ss;
										i = -1;
									} else {
										ss--;
										if (ss < 0) {
											i--;
											ss = 17;
										}
									}
								}
								i = 0;
								while (sfBandIndexCurrent.l[i] <= sb) {
									i++;
								}
								sfb = i;
								i = sfBandIndexCurrent.l[i];
								for (; sfb < 8; sfb++) {
									sb = sfBandIndexCurrent.l[sfb + 1]-sfBandIndexCurrent.l[sfb];
									for (; sb > 0; sb--) {
										is_pos[i] = scalefac[1].l[sfb];
										if (is_pos[i] != 7) {
											if (lsf) {
												i_stereo_k_values(is_pos[i], io_type, i);
											} else {
												is_ratio[i] = TAN12[is_pos[i]];
											}
										}
										i++;
									}
								}
							} // for (j=0 ...
						} else { // if (gr_info.mixed_block_flag)
							for (j = 0; j < 3; j++) {
								sfbcnt = -1;
								for (sfb = 12; sfb >= 0; sfb--) {
									temp = sfBandIndexCurrent.s[sfb];
									lines = sfBandIndexCurrent.s[sfb + 1] - temp;
									i = (temp << 2) - temp + (j+1) * lines - 1;
									while (lines > 0) {
										if (ro[1][i / 18][i % 18] != 0.0) {
											sfbcnt = sfb;
											sfb = -10;
											lines = -10;
										}
										lines--;
										i--;
									}
								}
								sfb = sfbcnt + 1;
								while (sfb < 12) {
									temp = sfBandIndexCurrent.s[sfb];
									sb = sfBandIndexCurrent.s[sfb + 1] - temp;
									i = (temp << 2) - temp + j * sb;
									for (; sb > 0; sb--) {
										is_pos[i] = scalefac[1].s[j][sfb];
										if (is_pos[i] != 7) {
											if (lsf) {
												i_stereo_k_values(is_pos[i], io_type, i);
											} else {
												is_ratio[i] = TAN12[is_pos[i]];
											}
										}
										i++;
									}
									sfb++;
								}
								temp = sfBandIndexCurrent.s[10];
								temp2= sfBandIndexCurrent.s[11];
								sb = temp2 - temp;
								sfb = (temp << 2) - temp + j * sb;
								sb = sfBandIndexCurrent.s[12] - temp2;
								i = (temp2 << 2) - temp2 + j * sb;
								for (; sb > 0; sb--) {
									is_pos[i] = is_pos[sfb];
									if (lsf) {
										k[0][i] = k[0][sfb];
										k[1][i] = k[1][sfb];
									} else {
										is_ratio[i] = is_ratio[sfb];
									}
									i++;
								}
							} // for (sfb=12
						} // for (j=0 ...
					} else { // if (gr_info.window_switching_flag ...
						i = 31;
						ss = 17;
						sb = 0;
						while (i >= 0) {
							if (ro[1][i][ss] != 0.0) {
								sb = (i << 4) + (i << 1) + ss;
								i = -1;
							} else {
								ss--;
								if (ss < 0) {
									i--;
									ss = 17;
								}
							}
						}
						i = 0;
						while (sfBandIndexCurrent.l[i] <= sb) {
							i++;
						}
						sfb = i;
						i = sfBandIndexCurrent.l[i];
						for (; sfb < 21; sfb++) {
							sb = sfBandIndexCurrent.l[sfb + 1] - sfBandIndexCurrent.l[sfb];
							for (; sb > 0; sb--) {
								is_pos[i] = scalefac[1].l[sfb];
								if (is_pos[i] != 7) {
									if (lsf) {
										i_stereo_k_values(is_pos[i], io_type, i);
									} else {
										is_ratio[i] = TAN12[is_pos[i]];
									}
								}
								i++;
							}
						}
						sfb = sfBandIndexCurrent.l[20];
						for (sb = 576 - sfBandIndexCurrent.l[21]; (sb > 0) && (i < 576); sb--) {
							is_pos[i] = is_pos[sfb]; // error here : i >= 576
							if (lsf) {
								k[0][i] = k[0][sfb];
								k[1][i] = k[1][sfb];
							} else {
								is_ratio[i] = is_ratio[sfb];
							}
							i++;
						} // if (gr_info.mixed_block_flag)
					} // if (gr_info.window_switching_flag ...
				} // if (i_stereo)
				i = 0;
				for (sb = 0; sb < SBLIMIT; sb++) {
					for (ss = 0; ss < SSLIMIT; ss++) {
						if (is_pos[i] == 7) {
							if (ms_stereo) {
								lr[0][sb][ss] = (ro[0][sb][ss] + ro[1][sb][ss]) * 0.707106781;
								lr[1][sb][ss] = (ro[0][sb][ss] - ro[1][sb][ss]) * 0.707106781;
							} else {
								lr[0][sb][ss] = ro[0][sb][ss];
								lr[1][sb][ss] = ro[1][sb][ss];
							}
						} else if (i_stereo) {
							if (lsf) {
								lr[0][sb][ss] = ro[0][sb][ss] * k[0][i];
								lr[1][sb][ss] = ro[0][sb][ss] * k[1][i];
							} else {
								lr[1][sb][ss] = ro[0][sb][ss] / (1 + is_ratio[i]);
								lr[0][sb][ss] = lr[1][sb][ss] * is_ratio[i];
							}
						}
						i++;
					}
				}
			}
		}

		protected function antialias(ch:int, gr:int):void
		{
			var sb18:int;
			var ss:int;
			var sb18lim:int;
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			// 31 alias-reduction operations between each pair of sub-bands
			// with 8 butterflies between each pair
			if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2) && !(gr_info.mixed_block_flag != 0)) {
				return;
			}
			if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2) && (gr_info.mixed_block_flag != 0)) {
				sb18lim = 18;
			} else {
				sb18lim = 558;
			}
			for (sb18 = 0; sb18 < sb18lim; sb18 += 18) {
				for (ss = 0; ss < 8; ss++) {
					var src_idx1:int = sb18 + 17 - ss;
					var src_idx2:int = sb18 + 18 + ss;
					var bu:Number = out_1d[src_idx1];
					var bd:Number = out_1d[src_idx2];
					out_1d[src_idx1] = (bu * cs[ss]) - (bd * ca[ss]);
					out_1d[src_idx2] = (bd * cs[ss]) + (bu * ca[ss]);
				}
			}
		}

		protected function hybrid(ch:int, gr:int):void
		{
			var bt:int;
			var sb18:int;
			var cc:int;
			var gr_info:GRInfo = si.ch[ch].gr[gr];
			var prvblk_ch:Vector.<Number> = prevblck[ch];
			var tsOut:Vector.<Number>;
			for (sb18 = 0; sb18 < 576; sb18 += 18) {
				bt = ((gr_info.window_switching_flag != 0) && (gr_info.mixed_block_flag != 0) && (sb18 < 36)) ? 0 : gr_info.block_type;
				tsOut = out_1d;
				for (cc = 0; cc < 18; cc++) {
					tsOutCopy[cc] = tsOut[cc + sb18];
				}
				inv_mdct(tsOutCopy, rawout, bt);
				for (cc = 0; cc < 18; cc++) {
					tsOut[cc + sb18] = tsOutCopy[cc];
				}
				// overlap addition
				tsOut[sb18] = rawout[0] + prvblk_ch[sb18 + 0];
				prvblk_ch[sb18] = rawout[18];
				tsOut[1 + sb18] = rawout[1]  + prvblk_ch[sb18 + 1];
				prvblk_ch[sb18 + 1] = rawout[19];
				tsOut[2 + sb18] = rawout[2]  + prvblk_ch[sb18 + 2];
				prvblk_ch[sb18 + 2] = rawout[20];
				tsOut[3 + sb18] = rawout[3]  + prvblk_ch[sb18 + 3];
				prvblk_ch[sb18 + 3] = rawout[21];
				tsOut[4 + sb18] = rawout[4]  + prvblk_ch[sb18 + 4];
				prvblk_ch[sb18 + 4] = rawout[22];
				tsOut[5 + sb18] = rawout[5]  + prvblk_ch[sb18 + 5];
				prvblk_ch[sb18 + 5] = rawout[23];
				tsOut[6 + sb18] = rawout[6]  + prvblk_ch[sb18 + 6];
				prvblk_ch[sb18 + 6] = rawout[24];
				tsOut[7 + sb18] = rawout[7]  + prvblk_ch[sb18 + 7];
				prvblk_ch[sb18 + 7] = rawout[25];
				tsOut[8 + sb18] = rawout[8]  + prvblk_ch[sb18 + 8];
				prvblk_ch[sb18 + 8] = rawout[26];
				tsOut[9 + sb18] = rawout[9]  + prvblk_ch[sb18 + 9];
				prvblk_ch[sb18 + 9] = rawout[27];
				tsOut[10 + sb18] = rawout[10] + prvblk_ch[sb18 + 10];
				prvblk_ch[sb18 + 10] = rawout[28];
				tsOut[11 + sb18] = rawout[11] + prvblk_ch[sb18 + 11];
				prvblk_ch[sb18 + 11] = rawout[29];
				tsOut[12 + sb18] = rawout[12] + prvblk_ch[sb18 + 12];
				prvblk_ch[sb18 + 12] = rawout[30];
				tsOut[13 + sb18] = rawout[13] + prvblk_ch[sb18 + 13];
				prvblk_ch[sb18 + 13] = rawout[31];
				tsOut[14 + sb18] = rawout[14] + prvblk_ch[sb18 + 14];
				prvblk_ch[sb18 + 14] = rawout[32];
				tsOut[15 + sb18] = rawout[15] + prvblk_ch[sb18 + 15];
				prvblk_ch[sb18 + 15] = rawout[33];
				tsOut[16 + sb18] = rawout[16] + prvblk_ch[sb18 + 16];
				prvblk_ch[sb18 + 16] = rawout[34];
				tsOut[17 + sb18] = rawout[17] + prvblk_ch[sb18 + 17];
				prvblk_ch[sb18 + 17] = rawout[35];
			}
		}

		public function inv_mdct(inp:Vector.<Number>, outp:Vector.<Number>, block_type:int):void
		{
			var win_bt:Vector.<Number>;
			var i:int;
			var tmpf_0:Number, tmpf_1:Number, tmpf_2:Number, tmpf_3:Number, tmpf_4:Number
			var tmpf_5:Number, tmpf_6:Number, tmpf_7:Number, tmpf_8:Number, tmpf_9:Number;
			var tmpf_10:Number, tmpf_11:Number, tmpf_12:Number, tmpf_13:Number, tmpf_14:Number
			var tmpf_15:Number, tmpf_16:Number, tmpf_17:Number;
			tmpf_0 = tmpf_1 = tmpf_2 = tmpf_3 = tmpf_4 = tmpf_5 = tmpf_6 = tmpf_7 = tmpf_8 = tmpf_9 =
			tmpf_10 = tmpf_11 = tmpf_12 = tmpf_13 = tmpf_14 = tmpf_15 = tmpf_16 = tmpf_17 = 0.0;
			if(block_type == 2) {
				outp[0] = 0.0;
				outp[1] = 0.0;
				outp[2] = 0.0;
				outp[3] = 0.0;
				outp[4] = 0.0;
				outp[5] = 0.0;
				outp[6] = 0.0;
				outp[7] = 0.0;
				outp[8] = 0.0;
				outp[9] = 0.0;
				outp[10] = 0.0;
				outp[11] = 0.0;
				outp[12] = 0.0;
				outp[13] = 0.0;
				outp[14] = 0.0;
				outp[15] = 0.0;
				outp[16] = 0.0;
				outp[17] = 0.0;
				outp[18] = 0.0;
				outp[19] = 0.0;
				outp[20] = 0.0;
				outp[21] = 0.0;
				outp[22] = 0.0;
				outp[23] = 0.0;
				outp[24] = 0.0;
				outp[25] = 0.0;
				outp[26] = 0.0;
				outp[27] = 0.0;
				outp[28] = 0.0;
				outp[29] = 0.0;
				outp[30] = 0.0;
				outp[31] = 0.0;
				outp[32] = 0.0;
				outp[33] = 0.0;
				outp[34] = 0.0;
				outp[35] = 0.0;
				var six_i:int = 0;
				for (i = 0; i < 3; i++)
				{
					// 12 point IMDCT
					// Begin 12 point IDCT
					// Input aliasing for 12 pt IDCT
					inp[15 + i] += inp[12 + i];
					inp[12 + i] += inp[9 + i];
					inp[9 + i] += inp[6 + i];
					inp[6 + i] += inp[3 + i];
					inp[3 + i] += inp[0 + i];
					
					// Input aliasing on odd indices (for 6 point IDCT)
					inp[15 + i] += inp[9 + i];
					inp[9 + i] += inp[3 + i];
					
					// 3 point IDCT on even indices
					var pp1:Number = inp[6 + i] * 0.866025403;
					var pp2:Number = inp[12 + i] * 0.5;
					var sum:Number = inp[i] + pp2;
					tmpf_1 = inp[i] - inp[12 + i];
					tmpf_0 = sum + pp1;
					tmpf_2 = sum - pp1;
					
					// End 3 point IDCT on even indices
					// 3 point IDCT on odd indices (for 6 point IDCT)
					pp2 = inp[15 + i] * 0.5;
					pp1 = inp[9 + i] * 0.866025403;
					sum = inp[3 + i] + pp2;
					tmpf_4 = inp[3 + i] - inp[15 + i];
					tmpf_5 = sum + pp1;
					tmpf_3 = sum - pp1;
					
					// End 3 point IDCT on odd indices
					// Twiddle factors on odd indices (for 6 point IDCT)
					tmpf_3 *= 1.931851653;
					tmpf_4 *= 0.707106781;
					tmpf_5 *= 0.517638090;

					// Output butterflies on 2 3 point IDCT's (for 6 point IDCT)
					var save:Number = tmpf_0;
					tmpf_0 += tmpf_5;
					tmpf_5 = save - tmpf_5;
					save = tmpf_1;
					tmpf_1 += tmpf_4;
					tmpf_4 = save - tmpf_4;
					save = tmpf_2;
					tmpf_2 += tmpf_3;
					tmpf_3 = save - tmpf_3;

					// End 6 point IDCT
					// Twiddle factors on indices (for 12 point IDCT)
					tmpf_0 *= 0.504314480;
					tmpf_1 *= 0.541196100;
					tmpf_2 *= 0.630236207;
					tmpf_3 *= 0.821339815;
					tmpf_4 *= 1.306562965;
					tmpf_5 *= 3.830648788;

					// End 12 point IDCT
					// Shift to 12 point modified IDCT, multiply by window type 2
					tmpf_8 = -tmpf_0 * 0.793353340;
					tmpf_9 = -tmpf_0 * 0.608761429;
					tmpf_7 = -tmpf_1 * 0.923879532;
					tmpf_10 = -tmpf_1 * 0.382683432;
					tmpf_6 = -tmpf_2 * 0.991444861;
					tmpf_11 = -tmpf_2 * 0.130526192;
					tmpf_0 = tmpf_3;
					tmpf_1 = tmpf_4 * 0.382683432;
					tmpf_2 = tmpf_5 * 0.608761429;
					tmpf_3 = -tmpf_5 * 0.793353340;
					tmpf_4 = -tmpf_4 * 0.923879532;
					tmpf_5 = -tmpf_0 * 0.991444861;
					tmpf_0 *= 0.130526192;

					outp[six_i + 6]  += tmpf_0;
					outp[six_i + 7]  += tmpf_1;
					outp[six_i + 8]  += tmpf_2;
					outp[six_i + 9]  += tmpf_3;
					outp[six_i + 10] += tmpf_4;
					outp[six_i + 11] += tmpf_5;
					outp[six_i + 12] += tmpf_6;
					outp[six_i + 13] += tmpf_7;
					outp[six_i + 14] += tmpf_8;
					outp[six_i + 15] += tmpf_9;
					outp[six_i + 16] += tmpf_10;
					outp[six_i + 17] += tmpf_11;

					six_i += 6;
				}
			} else {
				// 36 point IDCT
				// input aliasing for 36 point IDCT
				inp[17] += inp[16];
				inp[16] += inp[15];
				inp[15] += inp[14];
				inp[14] += inp[13];
				inp[13] += inp[12];
				inp[12] += inp[11];
				inp[11] += inp[10];
				inp[10] += inp[9];
				inp[9] += inp[8];
				inp[8] += inp[7];
				inp[7] += inp[6];
				inp[6] += inp[5];
				inp[5] += inp[4];
				inp[4] += inp[3];
				inp[3] += inp[2];
				inp[2] += inp[1];
				inp[1] += inp[0];

				// 18 point IDCT for odd indices
				// input aliasing for 18 point IDCT
				inp[17] += inp[15];
				inp[15] += inp[13];
				inp[13] += inp[11];
				inp[11] += inp[9];
				inp[9] += inp[7];
				inp[7] += inp[5];
				inp[5] += inp[3];
				inp[3] += inp[1];

				var tmp0:Number, tmp1:Number, tmp2:Number, tmp3:Number, tmp4:Number
				var tmp0_:Number, tmp1_:Number, tmp2_:Number, tmp3_:Number;
				var tmp0o:Number, tmp1o:Number, tmp2o:Number, tmp3o:Number, tmp4o:Number;
				var tmp0_o:Number, tmp1_o:Number, tmp2_o:Number, tmp3_o:Number;

				// Fast 9 Point Inverse Discrete Cosine Transform
				//
				// By  Francois-Raymond Boyer
				//         mailto:boyerf@iro.umontreal.ca
				//         http://www.iro.umontreal.ca/~boyerf
				//
				// The code has been optimized for Intel processors
				//  (takes a lot of time to convert float to and from iternal FPU representation)
				//
				// It is a simple "factorization" of the IDCT matrix.

				// 9 point IDCT on even indices
				// 5 points on odd indices (not realy an IDCT)
				var i00:Number = inp[0] + inp[0];
				var iip12:Number = i00 + inp[12];
				tmp0 = iip12 + inp[4] * 1.8793852415718  + inp[8] * 1.532088886238   + inp[16] * 0.34729635533386;
				tmp1 = i00   + inp[4]                    - inp[8] - inp[12] - inp[12] - inp[16];
				tmp2 = iip12 - inp[4] * 0.34729635533386 - inp[8] * 1.8793852415718  + inp[16] * 1.532088886238;
				tmp3 = iip12 - inp[4] * 1.532088886238   + inp[8] * 0.34729635533386 - inp[16] * 1.8793852415718;
				tmp4 = inp[0] - inp[4]                   + inp[8] - inp[12]          + inp[16];

				// 4 points on even indices
				var i66_:Number = inp[6] * 1.732050808; // Sqrt[3]
				tmp0_ = inp[2] * 1.9696155060244  + i66_ + inp[10] * 1.2855752193731  + inp[14] * 0.68404028665134;
				tmp1_ = (inp[2]                   - inp[10]                           - inp[14]) * 1.732050808;
				tmp2_ = inp[2] * 1.2855752193731  - i66_ - inp[10] * 0.68404028665134 + inp[14] * 1.9696155060244;
				tmp3_ = inp[2] * 0.68404028665134 - i66_ + inp[10] * 1.9696155060244  - inp[14] * 1.2855752193731;

				// 9 point IDCT on odd indices
				// 5 points on odd indices (not realy an IDCT)
				var i0:Number = inp[1] + inp[1];
				var i0p12:Number = i0 + inp[12 + 1];
				tmp0o = i0p12   + inp[4+1] * 1.8793852415718  + inp[8+1] * 1.532088886238        + inp[16+1] * 0.34729635533386;
				tmp1o = i0      + inp[4+1]                    - inp[8+1] - inp[12+1] - inp[12+1] - inp[16+1];
				tmp2o = i0p12   - inp[4+1] * 0.34729635533386 - inp[8+1] * 1.8793852415718       + inp[16+1] * 1.532088886238;
				tmp3o = i0p12   - inp[4+1] * 1.532088886238   + inp[8+1] * 0.34729635533386      - inp[16+1] * 1.8793852415718;
				tmp4o = (inp[1] - inp[4+1]                    + inp[8+1] - inp[12+1]             + inp[16+1]) * 0.707106781; // Twiddled

				// 4 points on even indices
				var i6_:Number = inp[6+1] * 1.732050808; // Sqrt[3]
				tmp0_o = inp[2+1] * 1.9696155060244  + i6_ + inp[10+1] * 1.2855752193731  + inp[14+1] * 0.68404028665134;
				tmp1_o = (inp[2+1]                         - inp[10+1]                    - inp[14+1]) * 1.732050808;
				tmp2_o = inp[2+1] * 1.2855752193731  - i6_ - inp[10+1] * 0.68404028665134 + inp[14+1] * 1.9696155060244;
				tmp3_o = inp[2+1] * 0.68404028665134 - i6_ + inp[10+1] * 1.9696155060244  - inp[14+1] * 1.2855752193731;

				// Twiddle factors on odd indices
				// and
				// Butterflies on 9 point IDCT's
				// and
				// twiddle factors for 36 point IDCT
				var e:Number;
				var o:Number;
				e = tmp0 + tmp0_;  o = (tmp0o + tmp0_o) * 0.501909918;  tmpf_0 = e + o;  tmpf_17 = e - o;
				e = tmp1 + tmp1_;  o = (tmp1o + tmp1_o) * 0.517638090;  tmpf_1 = e + o;  tmpf_16 = e - o;
				e = tmp2 + tmp2_;  o = (tmp2o + tmp2_o) * 0.551688959;  tmpf_2 = e + o;  tmpf_15 = e - o;
				e = tmp3 + tmp3_;  o = (tmp3o + tmp3_o) * 0.610387294;  tmpf_3 = e + o;  tmpf_14 = e - o;
				tmpf_4 = tmp4 + tmp4o;
				tmpf_13 = tmp4 - tmp4o;
				e = tmp3 - tmp3_;  o = (tmp3o - tmp3_o) * 0.871723397;  tmpf_5 = e + o;  tmpf_12 = e - o;
				e = tmp2 - tmp2_;  o = (tmp2o - tmp2_o) * 1.183100792;  tmpf_6 = e + o;  tmpf_11 = e - o;
				e = tmp1 - tmp1_;  o = (tmp1o - tmp1_o) * 1.931851653;  tmpf_7 = e + o;  tmpf_10 = e - o;
				e = tmp0 - tmp0_;  o = (tmp0o - tmp0_o) * 5.736856623;  tmpf_8 = e + o;  tmpf_9 =  e - o;

				// end 36 point IDCT
				// shift to modified IDCT
				win_bt = win[block_type];

				outp[0] =- tmpf_9  * win_bt[0];
				outp[1] =- tmpf_10 * win_bt[1];
				outp[2] =- tmpf_11 * win_bt[2];
				outp[3] =- tmpf_12 * win_bt[3];
				outp[4] =- tmpf_13 * win_bt[4];
				outp[5] =- tmpf_14 * win_bt[5];
				outp[6] =- tmpf_15 * win_bt[6];
				outp[7] =- tmpf_16 * win_bt[7];
				outp[8] =- tmpf_17 * win_bt[8];
				outp[9] = tmpf_17 * win_bt[9];
				outp[10] = tmpf_16 * win_bt[10];
				outp[11] = tmpf_15 * win_bt[11];
				outp[12] = tmpf_14 * win_bt[12];
				outp[13] = tmpf_13 * win_bt[13];
				outp[14] = tmpf_12 * win_bt[14];
				outp[15] = tmpf_11 * win_bt[15];
				outp[16] = tmpf_10 * win_bt[16];
				outp[17] = tmpf_9 * win_bt[17];
				outp[18] = tmpf_8 * win_bt[18];
				outp[19] = tmpf_7 * win_bt[19];
				outp[20] = tmpf_6 * win_bt[20];
				outp[21] = tmpf_5 * win_bt[21];
				outp[22] = tmpf_4 * win_bt[22];
				outp[23] = tmpf_3 * win_bt[23];
				outp[24] = tmpf_2 * win_bt[24];
				outp[25] = tmpf_1 * win_bt[25];
				outp[26] = tmpf_0 * win_bt[26];
				outp[27] = tmpf_0 * win_bt[27];
				outp[28] = tmpf_1 * win_bt[28];
				outp[29] = tmpf_2 * win_bt[29];
				outp[30] = tmpf_3 * win_bt[30];
				outp[31] = tmpf_4 * win_bt[31];
				outp[32] = tmpf_5 * win_bt[32];
				outp[33] = tmpf_6 * win_bt[33];
				outp[34] = tmpf_7 * win_bt[34];
				outp[35] = tmpf_8 * win_bt[35];
			}
		}
		
		protected function createReorderTable(scalefac_band:Vector.<int>):Vector.<int> {
			var j:int = 0;
			var ix:Vector.<int> = new Vector.<int>(576, true);
			for (var sfb:uint = 0; sfb < 13; sfb++) {
				var start:int = scalefac_band[sfb];
				var end:int = scalefac_band[sfb + 1];
				for (var window:uint = 0; window < 3; window++) {
					for (var i:int = start; i < end; i++) {
						ix[3 * i + window] = j++;
					}
				}
			}
			return ix;
		}


		protected function initialize():void
		{
			is_1d = new Vector.<int>(SBLIMIT * SSLIMIT + 4, true);
			ro = (new VectorNumber3D(2, SBLIMIT, SSLIMIT)).v;
			lr = (new VectorNumber3D(2, SBLIMIT, SSLIMIT)).v;
			out_1d = new Vector.<Number>(SBLIMIT * SSLIMIT, true);
			prevblck = (new VectorNumber2D(2, SBLIMIT * SSLIMIT)).v;
			k = (new VectorNumber2D(2, SBLIMIT * SSLIMIT)).v;
			nonzero = new Vector.<int>(2, true);
			
			scalefac = new Vector.<Temporaire2>(2, true);
			scalefac[0] = new Temporaire2();
			scalefac[1] = new Temporaire2();
			
			sfBandIndex = new Vector.<SBI>(9, true);
			var l0:Vector.<int> = Vector.<int>([ 0,6,12,18,24,30,36,44,54,66,80,96,116,140,168,200,238,284,336,396,464,522,576 ]);
			var s0:Vector.<int> = Vector.<int>([ 0,4,8,12,18,24,32,42,56,74,100,132,174,192 ]);
			var l1:Vector.<int> = Vector.<int>([ 0,6,12,18,24,30,36,44,54,66,80,96,114,136,162,194,232,278,330,394,464,540,576 ]);
			var s1:Vector.<int> = Vector.<int>([ 0,4,8,12,18,26,36,48,62,80,104,136,180,192 ]);
			var l2:Vector.<int> = Vector.<int>([ 0,6,12,18,24,30,36,44,54,66,80,96,116,140,168,200,238,284,336,396,464,522,576 ]);
			var s2:Vector.<int> = Vector.<int>([ 0,4,8,12,18,26,36,48,62,80,104,134,174,192 ]);
			var l3:Vector.<int> = Vector.<int>([ 0,4,8,12,16,20,24,30,36,44,52,62,74,90,110,134,162,196,238,288,342,418,576 ]);
			var s3:Vector.<int> = Vector.<int>([ 0,4,8,12,16,22,30,40,52,66,84,106,136,192 ]);
			var l4:Vector.<int> = Vector.<int>([ 0,4,8,12,16,20,24,30,36,42,50,60,72,88,106,128,156,190,230,276,330,384,576 ]);
			var s4:Vector.<int> = Vector.<int>([ 0,4,8,12,16,22,28,38,50,64,80,100,126,192 ]);
			var l5:Vector.<int> = Vector.<int>([ 0,4,8,12,16,20,24,30,36,44,54,66,82,102,126,156,194,240,296,364,448,550,576 ]);
			var s5:Vector.<int> = Vector.<int>([ 0,4,8,12,16,22,30,42,58,78,104,138,180,192 ]);
			var l6:Vector.<int> = Vector.<int>([ 0,6,12,18,24,30,36,44,54,66,80,96,116,140,168,200,238,284,336,396,464,522,576 ]);
			var s6:Vector.<int> = Vector.<int>([ 0,4,8,12,18,26,36,48,62,80,104,134,174,192 ]);
			var l7:Vector.<int> = Vector.<int>([ 0,6,12,18,24,30,36,44,54,66,80,96,116,140,168,200,238,284,336,396,464,522,576 ]);
			var s7:Vector.<int> = Vector.<int>([ 0,4,8,12,18,26,36,48,62,80,104,134,174,192 ]);
			var l8:Vector.<int> = Vector.<int>([ 0,12,24,36,48,60,72,88,108,132,160,192,232,280,336,400,476,566,568,570,572,574,576 ]);
			var s8:Vector.<int> = Vector.<int>([ 0,8,16,24,36,52,72,96,124,160,162,164,166,192 ]);
			sfBandIndex[0] = new SBI(l0, s0);
			sfBandIndex[1] = new SBI(l1, s1);
			sfBandIndex[2] = new SBI(l2, s2);
			sfBandIndex[3] = new SBI(l3, s3);
			sfBandIndex[4] = new SBI(l4, s4);
			sfBandIndex[5] = new SBI(l5, s5);
			sfBandIndex[6] = new SBI(l6, s6);
			sfBandIndex[7] = new SBI(l7, s7);
			sfBandIndex[8] = new SBI(l8, s8);
			
			reorder_table = new Vector.<Vector.<int>>(9, true);
			for (var i:uint = 0; i < 9; i++) {
				reorder_table[i] = createReorderTable(sfBandIndex[i].s);
			}

			sftable = new SFTable(
				Vector.<int>([ 0, 6, 11, 16, 21 ]),
				Vector.<int>([ 0, 6, 12 ])
			);
			
			scalefac_buffer = new Vector.<int>(54, true);

			//stream = stream0;
			//header = header0;
			//filter1 = filtera;
			//filter2 = filterb;
			//buffer = buffer0;
			
			channels = (currentFrame.channelMode == MPEGFrame.CHANNEL_MODE_MONO) ? 1 : 2;

			first_channel = 0;
			last_channel = (channels == 2) ? 1 : 0;
			
			max_gr = (currentFrame.version == MPEGFrame.MPEG_VERSION_1_0) ? 2 : 1;
			
			switch(currentFrame.version) {
				case MPEGFrame.MPEG_VERSION_1_0:
					sfreq = currentFrame.samplingrateIndex + 3;
					break;
				case MPEGFrame.MPEG_VERSION_2_5:
					sfreq = currentFrame.samplingrateIndex + 6;
					break;
				default: 
					sfreq = currentFrame.samplingrateIndex; 
					break;
			}
			sfBandIndexCurrent = sfBandIndex[sfreq];
			
			nonzero[0] = nonzero[1] = 576;
			
			si = new LayerIIISideInfo();
			
			seek_notify();
			
			initialized = true;
		}

		public function seek_notify():void {
			frame_start = 0;
			for (var ch:uint = 0; ch < 2; ch++) {
				for (var j:int = 0; j < 576; j++) {
					prevblck[ch][j] = 0.0;
				}
			}
			br = new BitReserve();
		}


		public static var pretab:Vector.<int> = Vector.<int>(
			[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 3, 2, 0 ]
		);
	
		public static var two_to_negative_half_pow:Vector.<Number> =
			Vector.<Number>([
				1.0000000000E+00, 7.0710678119E-01, 5.0000000000E-01, 3.5355339059E-01,
				2.5000000000E-01, 1.7677669530E-01, 1.2500000000E-01, 8.8388347648E-02,
				6.2500000000E-02, 4.4194173824E-02, 3.1250000000E-02, 2.2097086912E-02,
				1.5625000000E-02, 1.1048543456E-02, 7.8125000000E-03, 5.5242717280E-03,
				3.9062500000E-03, 2.7621358640E-03, 1.9531250000E-03, 1.3810679320E-03,
				9.7656250000E-04, 6.9053396600E-04, 4.8828125000E-04, 3.4526698300E-04,
				2.4414062500E-04, 1.7263349150E-04, 1.2207031250E-04, 8.6316745750E-05,
				6.1035156250E-05, 4.3158372875E-05, 3.0517578125E-05, 2.1579186438E-05,
				1.5258789062E-05, 1.0789593219E-05, 7.6293945312E-06, 5.3947966094E-06,
				3.8146972656E-06, 2.6973983047E-06, 1.9073486328E-06, 1.3486991523E-06,
				9.5367431641E-07, 6.7434957617E-07, 4.7683715820E-07, 3.3717478809E-07,
				2.3841857910E-07, 1.6858739404E-07, 1.1920928955E-07, 8.4293697022E-08,
				5.9604644775E-08, 4.2146848511E-08, 2.9802322388E-08, 2.1073424255E-08,
				1.4901161194E-08, 1.0536712128E-08, 7.4505805969E-09, 5.2683560639E-09,
				3.7252902985E-09, 2.6341780319E-09, 1.8626451492E-09, 1.3170890160E-09,
				9.3132257462E-10, 6.5854450798E-10, 4.6566128731E-10, 3.2927225399E-10
			]);
	
		public static const d43:Number = 4.0 / 3.0;
		public static var t_43:Vector.<Number> = create_t_43();
		protected static function create_t_43():Vector.<Number> {
			var _d43:Number = d43;
			var t43:Vector.<Number> = new Vector.<Number>(8192, true);
			for (var i:uint = 0; i < 8192; i++) {
				t43[i] = Math.pow(i, _d43);
			}
			return t43;
		}

		public static var io:Vector.<Vector.<Number>> =
			Vector.<Vector.<Number>>([
				Vector.<Number>([
					1.0000000000E+00, 8.4089641526E-01, 7.0710678119E-01, 5.9460355751E-01,
					5.0000000001E-01, 4.2044820763E-01, 3.5355339060E-01, 2.9730177876E-01,
					2.5000000001E-01, 2.1022410382E-01, 1.7677669530E-01, 1.4865088938E-01,
					1.2500000000E-01, 1.0511205191E-01, 8.8388347652E-02, 7.4325444691E-02,
					6.2500000003E-02, 5.2556025956E-02, 4.4194173826E-02, 3.7162722346E-02,
					3.1250000002E-02, 2.6278012978E-02, 2.2097086913E-02, 1.8581361173E-02,
					1.5625000001E-02, 1.3139006489E-02, 1.1048543457E-02, 9.2906805866E-03,
					7.8125000006E-03, 6.5695032447E-03, 5.5242717285E-03, 4.6453402934E-03
				]),
				Vector.<Number>([
					1.0000000000E+00, 7.0710678119E-01, 5.0000000000E-01, 3.5355339060E-01,
					2.5000000000E-01, 1.7677669530E-01, 1.2500000000E-01, 8.8388347650E-02,
					6.2500000001E-02, 4.4194173825E-02, 3.1250000001E-02, 2.2097086913E-02,
					1.5625000000E-02, 1.1048543456E-02, 7.8125000002E-03, 5.5242717282E-03,
					3.9062500001E-03, 2.7621358641E-03, 1.9531250001E-03, 1.3810679321E-03,
					9.7656250004E-04, 6.9053396603E-04, 4.8828125002E-04, 3.4526698302E-04,
					2.4414062501E-04, 1.7263349151E-04, 1.2207031251E-04, 8.6316745755E-05,
					6.1035156254E-05, 4.3158372878E-05, 3.0517578127E-05, 2.1579186439E-05
				])
			]);

		public static var TAN12:Vector.<Number> = 
			Vector.<Number>([
				0.0, 0.26794919, 0.57735027, 1.0,
				1.73205081, 3.73205081, 9.9999999e10, -3.73205081,
				-1.73205081, -1.0, -0.57735027, -0.26794919,
				0.0, 0.26794919, 0.57735027, 1.0
			]);

		protected static var slen:Vector.<Vector.<int>> =
			Vector.<Vector.<int>>([
				Vector.<int>([ 0, 0, 0, 0, 3, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4 ]),
				Vector.<int>([ 0, 1, 2, 3, 0, 1, 2, 3, 1, 2, 3, 1, 2, 3, 2, 3 ])
			]);
			
		public static var win:Vector.<Vector.<Number>> =
			Vector.<Vector.<Number>>([
				Vector.<Number>([
					-1.6141214951E-02, -5.3603178919E-02, -1.0070713296E-01, -1.6280817573E-01,
					-4.9999999679E-01, -3.8388735032E-01, -6.2061144372E-01, -1.1659756083E+00,
					-3.8720752656E+00, -4.2256286556E+00, -1.5195289984E+00, -9.7416483388E-01,
					-7.3744074053E-01, -1.2071067773E+00, -5.1636156596E-01, -4.5426052317E-01,
					-4.0715656898E-01, -3.6969460527E-01, -3.3876269197E-01, -3.1242222492E-01,
					-2.8939587111E-01, -2.6880081906E-01, -5.0000000266E-01, -2.3251417468E-01,
					-2.1596714708E-01, -2.0004979098E-01, -1.8449493497E-01, -1.6905846094E-01,
					-1.5350360518E-01, -1.3758624925E-01, -1.2103922149E-01, -2.0710679058E-01,
					-8.4752577594E-02, -6.4157525656E-02, -4.1131172614E-02, -1.4790705759E-02
				]),
				Vector.<Number>([
					-1.6141214951E-02, -5.3603178919E-02, -1.0070713296E-01, -1.6280817573E-01,
					-4.9999999679E-01, -3.8388735032E-01, -6.2061144372E-01, -1.1659756083E+00,
					-3.8720752656E+00, -4.2256286556E+00, -1.5195289984E+00, -9.7416483388E-01,
					-7.3744074053E-01, -1.2071067773E+00, -5.1636156596E-01, -4.5426052317E-01,
					-4.0715656898E-01, -3.6969460527E-01, -3.3908542600E-01, -3.1511810350E-01,
					-2.9642226150E-01, -2.8184548650E-01, -5.4119610000E-01, -2.6213228100E-01,
					-2.5387916537E-01, -2.3296291359E-01, -1.9852728987E-01, -1.5233534808E-01,
					-9.6496400054E-02, -3.3423828516E-02, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00
				]),
				Vector.<Number>([
					-4.8300800645E-02, -1.5715656932E-01, -2.8325045177E-01, -4.2953747763E-01,
					-1.2071067795E+00, -8.2426483178E-01, -1.1451749106E+00, -1.7695290101E+00,
					-4.5470225061E+00, -3.4890531002E+00, -7.3296292804E-01, -1.5076514758E-01,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00
				]),
				Vector.<Number>([
					0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00, 0.0000000000E+00,
					0.0000000000E+00, 0.0000000000E+00, -1.5076513660E-01, -7.3296291107E-01,
					-3.4890530566E+00, -4.5470224727E+00, -1.7695290031E+00, -1.1451749092E+00,
					-8.3137738100E-01, -1.3065629650E+00, -5.4142014250E-01, -4.6528974900E-01,
					-4.1066990750E-01, -3.7004680800E-01, -3.3876269197E-01, -3.1242222492E-01,
					-2.8939587111E-01, -2.6880081906E-01, -5.0000000266E-01, -2.3251417468E-01,
					-2.1596714708E-01, -2.0004979098E-01, -1.8449493497E-01, -1.6905846094E-01,
					-1.5350360518E-01, -1.3758624925E-01, -1.2103922149E-01, -2.0710679058E-01,
					-8.4752577594E-02, -6.4157525656E-02, -4.1131172614E-02, -1.4790705759E-02
				])
			]);

		protected static var nr_of_sfb_block:Vector.<Vector.<Vector.<int>>> =
			Vector.<Vector.<Vector.<int>>>([
				Vector.<Vector.<int>>([ Vector.<int>([ 6,5,5,5 ]), Vector.<int>([ 9,9,9,9 ]), Vector.<int>([ 6,9,9,9 ]) ]),
				Vector.<Vector.<int>>([ Vector.<int>([ 6,5,7,3 ]), Vector.<int>([ 9,9,12,6 ]), Vector.<int>([ 6,9,12,6 ]) ]),
				Vector.<Vector.<int>>([ Vector.<int>([ 11,10,0,0 ]), Vector.<int>([ 18,18,0,0 ]), Vector.<int>([ 15,18,0,0 ]) ]),
				Vector.<Vector.<int>>([ Vector.<int>([ 7,7,7,0 ]), Vector.<int>([ 12,12,12,0 ]), Vector.<int>([ 6,15,12,0 ]) ]),
				Vector.<Vector.<int>>([ Vector.<int>([ 6,6,6,3 ]), Vector.<int>([ 12,9,9,6 ]), Vector.<int>([ 6,12,9,6 ]) ]),
				Vector.<Vector.<int>>([ Vector.<int>([ 8,8,5,0 ]), Vector.<int>([ 15,12,9,0 ]), Vector.<int>([ 6,18,9,0 ]) ])
			]);
			
		protected static var cs:Vector.<Number> =
			Vector.<Number>([
				0.857492925712, 0.881741997318, 0.949628649103, 0.983314592492,
				0.995517816065, 0.999160558175, 0.999899195243, 0.999993155067
			]);

		protected static var ca:Vector.<Number> =
			Vector.<Number>([
				-0.5144957554270, -0.4717319685650, -0.3133774542040, -0.1819131996110,
				-0.0945741925262, -0.0409655828852, -0.0141985685725, -0.00369997467375
			]);
	}
}
