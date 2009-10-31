package com.codeazur.as3icy.decoder
{
	import flash.utils.ByteArray;
	
	public class SynthesisFilter
	{
		protected var v1:Vector.<Number>;
		protected var v2:Vector.<Number>;
		protected var actual_v:Vector.<Number>;
		protected var actual_write_pos:int;
		protected var samples:Vector.<Number>;
		protected var channel:int;
		protected var scalefactor:Number;
		protected var _tmpOut:Vector.<Number>;
		//private float[] eq;

		public function SynthesisFilter(channelnumber:int, factor:Number /*, eq0:Vector.<Number>*/)
		{
			v1 = new Vector.<Number>(512, true);
			v2 = new Vector.<Number>(512, true);
			samples = new Vector.<Number>(32);
			_tmpOut = new Vector.<Number>(32);
			channel = channelnumber;
			scalefactor = factor;
			reset();
		}

		public function reset():void {
			var i:int;
			for (i = 0; i < 512; i++) {
				v1[i] = v2[i] = 0.0;
			}
			for (i = 0; i < 32; i++) {
				samples[i] = 0.0;
			}
			actual_v = v1;
			actual_write_pos = 15;
		}

		public function input_samples(s:Vector.<Number>):void {
			for (var i:int = 31; i >= 0; i--) {		
				samples[i] = s[i]; /* * eq[i]*/
			}
		}

		public function calculate_pcm_samples(buffer:OutputBuffer):void {
			compute_new_v();	
			compute_pcm_samples(buffer);
			actual_write_pos = (actual_write_pos + 1) & 0xf;
			actual_v = (actual_v == v1) ? v2 : v1;
			// MDM: this may not be necessary. The Layer III decoder always
			// outputs 32 subband samples, but I haven't checked layer I & II.
			for (var i:int = 0; i < 32; i++) { 
				samples[i] = 0.0;
			}
		}

		protected function compute_new_v():void
		{
			var new_v0:Number, new_v1:Number, new_v2:Number, new_v3:Number;
			var new_v4:Number, new_v5:Number, new_v6:Number, new_v7:Number;
			var new_v8:Number, new_v9:Number, new_v10:Number, new_v11:Number;
			var new_v12:Number, new_v13:Number, new_v14:Number, new_v15:Number;
			var new_v16:Number, new_v17:Number, new_v18:Number, new_v19:Number;
			var new_v20:Number, new_v21:Number, new_v22:Number, new_v23:Number;
			var new_v24:Number, new_v25:Number, new_v26:Number, new_v27:Number;
			var new_v28:Number, new_v29:Number, new_v30:Number, new_v31:Number;

			new_v0 = new_v1 = new_v2 = new_v3 = new_v4 = new_v5 = new_v6 = new_v7 = new_v8 = new_v9 = 
			new_v10 = new_v11 = new_v12 = new_v13 = new_v14 = new_v15 = new_v16 = new_v17 = new_v18 = new_v19 = 
			new_v20 = new_v21 = new_v22 = new_v23 = new_v24 = new_v25 = new_v26 = new_v27 = new_v28 = new_v29 = 
			new_v30 = new_v31 = 0.0;

			var s0:Number = samples[0];
			var s1:Number = samples[1];
			var s2:Number = samples[2];
			var s3:Number = samples[3];
			var s4:Number = samples[4];
			var s5:Number = samples[5];
			var s6:Number = samples[6];
			var s7:Number = samples[7];
			var s8:Number = samples[8];
			var s9:Number = samples[9];
			var s10:Number = samples[10];
			var s11:Number = samples[11];
			var s12:Number = samples[12];
			var s13:Number = samples[13];
			var s14:Number = samples[14];
			var s15:Number = samples[15];
			var s16:Number = samples[16];
			var s17:Number = samples[17];
			var s18:Number = samples[18];
			var s19:Number = samples[19];
			var s20:Number = samples[20];
			var s21:Number = samples[21];
			var s22:Number = samples[22];
			var s23:Number = samples[23];
			var s24:Number = samples[24];
			var s25:Number = samples[25];
			var s26:Number = samples[26];
			var s27:Number = samples[27];
			var s28:Number = samples[28];
			var s29:Number = samples[29];
			var s30:Number = samples[30];
			var s31:Number = samples[31];

			var p0:Number = s0 + s31;
			var p1:Number = s1 + s30;
			var p2:Number = s2 + s29;
			var p3:Number = s3 + s28;
			var p4:Number = s4 + s27;
			var p5:Number = s5 + s26;
			var p6:Number = s6 + s25;
			var p7:Number = s7 + s24;
			var p8:Number = s8 + s23;
			var p9:Number = s9 + s22;
			var p10:Number = s10 + s21;
			var p11:Number = s11 + s20;
			var p12:Number = s12 + s19;
			var p13:Number = s13 + s18;
			var p14:Number = s14 + s17;
			var p15:Number = s15 + s16;

			var pp0:Number = p0 + p15;
			var pp1:Number = p1 + p14;
			var pp2:Number = p2 + p13;
			var pp3:Number = p3 + p12;
			var pp4:Number = p4 + p11;
			var pp5:Number = p5 + p10;
			var pp6:Number = p6 + p9;
			var pp7:Number = p7 + p8;
			var pp8:Number = (p0 - p15) * cos1_32;
			var pp9:Number = (p1 - p14) * cos3_32;
			var pp10:Number = (p2 - p13) * cos5_32;
			var pp11:Number = (p3 - p12) * cos7_32;
			var pp12:Number = (p4 - p11) * cos9_32;
			var pp13:Number = (p5 - p10) * cos11_32;
			var pp14:Number = (p6 - p9) * cos13_32;
			var pp15:Number = (p7 - p8) * cos15_32;

			p0 = pp0 + pp7;
			p1 = pp1 + pp6;
			p2 = pp2 + pp5;
			p3 = pp3 + pp4;
			p4 = (pp0 - pp7) * cos1_16;
			p5 = (pp1 - pp6) * cos3_16;
			p6 = (pp2 - pp5) * cos5_16;
			p7 = (pp3 - pp4) * cos7_16;
			p8 = pp8 + pp15;
			p9 = pp9 + pp14;
			p10 = pp10 + pp13;
			p11 = pp11 + pp12;
			p12 = (pp8 - pp15) * cos1_16;
			p13 = (pp9 - pp14) * cos3_16;
			p14 = (pp10 - pp13) * cos5_16;
			p15 = (pp11 - pp12) * cos7_16;

			pp0 = p0 + p3;
			pp1 = p1 + p2;
			pp2 = (p0 - p3) * cos1_8;
			pp3 = (p1 - p2) * cos3_8;
			pp4 = p4 + p7;
			pp5 = p5 + p6;
			pp6 = (p4 - p7) * cos1_8;
			pp7 = (p5 - p6) * cos3_8;
			pp8 = p8 + p11;
			pp9 = p9 + p10;
			pp10 = (p8 - p11) * cos1_8;
			pp11 = (p9 - p10) * cos3_8;
			pp12 = p12 + p15;
			pp13 = p13 + p14;
			pp14 = (p12 - p15) * cos1_8;
			pp15 = (p13 - p14) * cos3_8;

			p0 = pp0 + pp1;
			p1 = (pp0 - pp1) * cos1_4;
			p2 = pp2 + pp3;
			p3 = (pp2 - pp3) * cos1_4;
			p4 = pp4 + pp5;
			p5 = (pp4 - pp5) * cos1_4;
			p6 = pp6 + pp7;
			p7 = (pp6 - pp7) * cos1_4;
			p8 = pp8 + pp9;
			p9 = (pp8 - pp9) * cos1_4;
			p10 = pp10 + pp11;
			p11 = (pp10 - pp11) * cos1_4;
			p12 = pp12 + pp13;
			p13 = (pp12 - pp13) * cos1_4;
			p14 = pp14 + pp15;
			p15 = (pp14 - pp15) * cos1_4;

			// this is pretty insane coding
			var tmp1:Number;
			new_v19/*36-17*/ = -(new_v4 = (new_v12 = p7) + p5) - p6;
			new_v27/*44-17*/ = -p6 - p7 - p4;
			new_v6 = (new_v10 = (new_v14 = p15) + p11) + p13;
			new_v17/*34-17*/ = -(new_v2 = p15 + p13 + p9) - p14;
			new_v21/*38-17*/ = (tmp1 = -p14 - p15 - p10 - p11) - p13;
			new_v29/*46-17*/ = -p14 - p15 - p12 - p8;
			new_v25/*42-17*/ = tmp1 - p12;
			new_v31/*48-17*/ = -p0;
			new_v0 = p1;
			new_v23/*40-17*/ = -(new_v8 = p3) - p2;

			p0 = (s0 - s31) * cos1_64;
			p1 = (s1 - s30) * cos3_64;
			p2 = (s2 - s29) * cos5_64;
			p3 = (s3 - s28) * cos7_64;
			p4 = (s4 - s27) * cos9_64;
			p5 = (s5 - s26) * cos11_64;
			p6 = (s6 - s25) * cos13_64;
			p7 = (s7 - s24) * cos15_64;
			p8 = (s8 - s23) * cos17_64;
			p9 = (s9 - s22) * cos19_64;
			p10 = (s10 - s21) * cos21_64;
			p11 = (s11 - s20) * cos23_64;
			p12 = (s12 - s19) * cos25_64;
			p13 = (s13 - s18) * cos27_64;
			p14 = (s14 - s17) * cos29_64;
			p15 = (s15 - s16) * cos31_64;

			pp0 = p0 + p15;
			pp1 = p1 + p14;
			pp2 = p2 + p13;
			pp3 = p3 + p12;
			pp4 = p4 + p11;
			pp5 = p5 + p10;
			pp6 = p6 + p9;
			pp7 = p7 + p8;
			pp8 = (p0 - p15) * cos1_32;
			pp9 = (p1 - p14) * cos3_32;
			pp10 = (p2 - p13) * cos5_32;
			pp11 = (p3 - p12) * cos7_32;
			pp12 = (p4 - p11) * cos9_32;
			pp13 = (p5 - p10) * cos11_32;
			pp14 = (p6 - p9) * cos13_32;
			pp15 = (p7 - p8) * cos15_32;

			p0 = pp0 + pp7;
			p1 = pp1 + pp6;
			p2 = pp2 + pp5;
			p3 = pp3 + pp4;
			p4 = (pp0 - pp7) * cos1_16;
			p5 = (pp1 - pp6) * cos3_16;
			p6 = (pp2 - pp5) * cos5_16;
			p7 = (pp3 - pp4) * cos7_16;
			p8 = pp8 + pp15;
			p9 = pp9 + pp14;
			p10 = pp10 + pp13;
			p11 = pp11 + pp12;
			p12 = (pp8 - pp15) * cos1_16;
			p13 = (pp9 - pp14) * cos3_16;
			p14 = (pp10 - pp13) * cos5_16;
			p15 = (pp11 - pp12) * cos7_16;

			pp0 = p0 + p3;
			pp1 = p1 + p2;
			pp2 = (p0 - p3) * cos1_8;
			pp3 = (p1 - p2) * cos3_8;
			pp4 = p4 + p7;
			pp5 = p5 + p6;
			pp6 = (p4 - p7) * cos1_8;
			pp7 = (p5 - p6) * cos3_8;
			pp8 = p8 + p11;
			pp9 = p9 + p10;
			pp10 = (p8 - p11) * cos1_8;
			pp11 = (p9 - p10) * cos3_8;
			pp12 = p12 + p15;
			pp13 = p13 + p14;
			pp14 = (p12 - p15) * cos1_8;
			pp15 = (p13 - p14) * cos3_8;

			p0 = pp0 + pp1;
			p1 = (pp0 - pp1) * cos1_4;
			p2 = pp2 + pp3;
			p3 = (pp2 - pp3) * cos1_4;
			p4 = pp4 + pp5;
			p5 = (pp4 - pp5) * cos1_4;
			p6 = pp6 + pp7;
			p7 = (pp6 - pp7) * cos1_4;
			p8 = pp8 + pp9;
			p9 = (pp8 - pp9) * cos1_4;
			p10 = pp10 + pp11;
			p11 = (pp10 - pp11) * cos1_4;
			p12 = pp12 + pp13;
			p13 = (pp12 - pp13) * cos1_4;
			p14 = pp14 + pp15;
			p15 = (pp14 - pp15) * cos1_4;

			// manually doing something that a compiler should handle sucks
			// coding like this is hard to read
			var tmp2:Number;
			new_v5 = (new_v11 = (new_v13 = (new_v15 = p15) + p7) + p11) + p5 + p13;
			new_v7 = (new_v9 = p15 + p11 + p3) + p13;
			new_v16/*33-17*/ = -(new_v1 = (tmp1 = p13 + p15 + p9) + p1) - p14;
			new_v18/*35-17*/ = -(new_v3 = tmp1 + p5 + p7) - p6 - p14;

			new_v22/*39-17*/ = (tmp1 = -p10 - p11 - p14 - p15) - p13 - p2 - p3;
			new_v20/*37-17*/ = tmp1 - p13 - p5 - p6 - p7;
			new_v24/*41-17*/ = tmp1 - p12 - p2 - p3;
			new_v26/*43-17*/ = tmp1 - p12 - (tmp2 = p4 + p6 + p7);
			new_v30/*47-17*/ = (tmp1 = -p8 - p12 - p14 - p15) - p0;
			new_v28/*45-17*/ = tmp1 - tmp2;

			var dest:Vector.<Number> = actual_v;
			var pos:int = actual_write_pos;

			// insert V[0-15] (== new_v[0-15]) into actual v:	
			dest[0 + pos] = new_v0;
			dest[16 + pos] = new_v1;
			dest[32 + pos] = new_v2;
			dest[48 + pos] = new_v3;
			dest[64 + pos] = new_v4;
			dest[80 + pos] = new_v5;
			dest[96 + pos] = new_v6;
			dest[112 + pos] = new_v7;
			dest[128 + pos] = new_v8;
			dest[144 + pos] = new_v9;
			dest[160 + pos] = new_v10;
			dest[176 + pos] = new_v11;
			dest[192 + pos] = new_v12;
			dest[208 + pos] = new_v13;
			dest[224 + pos] = new_v14;
			dest[240 + pos] = new_v15;

			// V[16] is always 0.0:
			dest[256 + pos] = 0.0;

			// insert V[17-31] (== -new_v[15-1]) into actual v:
			dest[272 + pos] = -new_v15;
			dest[288 + pos] = -new_v14;
			dest[304 + pos] = -new_v13;
			dest[320 + pos] = -new_v12;
			dest[336 + pos] = -new_v11;
			dest[352 + pos] = -new_v10;
			dest[368 + pos] = -new_v9;
			dest[384 + pos] = -new_v8;
			dest[400 + pos] = -new_v7;
			dest[416 + pos] = -new_v6;
			dest[432 + pos] = -new_v5;
			dest[448 + pos] = -new_v4;
			dest[464 + pos] = -new_v3;
			dest[480 + pos] = -new_v2;
			dest[496 + pos] = -new_v1;

			dest = (actual_v == v1) ? v2 : v1;

			// insert V[32] (== -new_v[0]) into other v:
			dest[0 + pos] = -new_v0;

			// insert V[33-48] (== new_v[16-31]) into other v:
			dest[16 + pos] = new_v16;
			dest[32 + pos] = new_v17;
			dest[48 + pos] = new_v18;
			dest[64 + pos] = new_v19;
			dest[80 + pos] = new_v20;
			dest[96 + pos] = new_v21;
			dest[112 + pos] = new_v22;
			dest[128 + pos] = new_v23;
			dest[144 + pos] = new_v24;
			dest[160 + pos] = new_v25;
			dest[176 + pos] = new_v26;
			dest[192 + pos] = new_v27;
			dest[208 + pos] = new_v28;
			dest[224 + pos] = new_v29;
			dest[240 + pos] = new_v30;
			dest[256 + pos] = new_v31;

			// insert V[49-63] (== new_v[30-16]) into other v:
			dest[272 + pos] = new_v30;
			dest[288 + pos] = new_v29;
			dest[304 + pos] = new_v28;
			dest[320 + pos] = new_v27;
			dest[336 + pos] = new_v26;
			dest[352 + pos] = new_v25;
			dest[368 + pos] = new_v24;
			dest[384 + pos] = new_v23;
			dest[400 + pos] = new_v22;
			dest[416 + pos] = new_v21;
			dest[432 + pos] = new_v20;
			dest[448 + pos] = new_v19;
			dest[464 + pos] = new_v18;
			dest[480 + pos] = new_v17;
			dest[496 + pos] = new_v16; 			
		}

		protected function compute_pcm_samples(buffer:OutputBuffer):void {
			switch (actual_write_pos) {
				case 0: compute_pcm_samples0(); break;
				case 1: compute_pcm_samples1(); break;
				case 2: compute_pcm_samples2(); break;
				case 3: compute_pcm_samples3(); break;
				case 4: compute_pcm_samples4(); break;
				case 5: compute_pcm_samples5(); break;
				case 6: compute_pcm_samples6(); break;
				case 7: compute_pcm_samples7(); break;
				case 8: compute_pcm_samples8(); break;
				case 9: compute_pcm_samples9(); break;
				case 10: compute_pcm_samples10(); break;
				case 11: compute_pcm_samples11(); break;
				case 12: compute_pcm_samples12(); break;
				case 13: compute_pcm_samples13(); break;
				case 14: compute_pcm_samples14(); break;
				case 15: compute_pcm_samples15(); break;
			}
			if (buffer != null) {
				buffer.appendSamples(channel, _tmpOut);
			}
		}

		protected function compute_pcm_samples0():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[0 + dvp] * dp[0] +
					vp[15 + dvp] * dp[1] +
					vp[14 + dvp] * dp[2] +
					vp[13 + dvp] * dp[3] +
					vp[12 + dvp] * dp[4] +
					vp[11 + dvp] * dp[5] +
					vp[10 + dvp] * dp[6] +
					vp[9 + dvp] * dp[7] +
					vp[8 + dvp] * dp[8] +
					vp[7 + dvp] * dp[9] +
					vp[6 + dvp] * dp[10] +
					vp[5 + dvp] * dp[11] +
					vp[4 + dvp] * dp[12] +
					vp[3 + dvp] * dp[13] +
					vp[2 + dvp] * dp[14] +
					vp[1 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples1():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[1 + dvp] * dp[0] +
					vp[0 + dvp] * dp[1] +
					vp[15 + dvp] * dp[2] +
					vp[14 + dvp] * dp[3] +
					vp[13 + dvp] * dp[4] +
					vp[12 + dvp] * dp[5] +
					vp[11 + dvp] * dp[6] +
					vp[10 + dvp] * dp[7] +
					vp[9 + dvp] * dp[8] +
					vp[8 + dvp] * dp[9] +
					vp[7 + dvp] * dp[10] +
					vp[6 + dvp] * dp[11] +
					vp[5 + dvp] * dp[12] +
					vp[4 + dvp] * dp[13] +
					vp[3 + dvp] * dp[14] +
					vp[2 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples2():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[2 + dvp] * dp[0] +
					vp[1 + dvp] * dp[1] +
					vp[0 + dvp] * dp[2] +
					vp[15 + dvp] * dp[3] +
					vp[14 + dvp] * dp[4] +
					vp[13 + dvp] * dp[5] +
					vp[12 + dvp] * dp[6] +
					vp[11 + dvp] * dp[7] +
					vp[10 + dvp] * dp[8] +
					vp[9 + dvp] * dp[9] +
					vp[8 + dvp] * dp[10] +
					vp[7 + dvp] * dp[11] +
					vp[6 + dvp] * dp[12] +
					vp[5 + dvp] * dp[13] +
					vp[4 + dvp] * dp[14] +
					vp[3 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples3():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[3 + dvp] * dp[0] +
					vp[2 + dvp] * dp[1] +
					vp[1 + dvp] * dp[2] +
					vp[0 + dvp] * dp[3] +
					vp[15 + dvp] * dp[4] +
					vp[14 + dvp] * dp[5] +
					vp[13 + dvp] * dp[6] +
					vp[12 + dvp] * dp[7] +
					vp[11 + dvp] * dp[8] +
					vp[10 + dvp] * dp[9] +
					vp[9 + dvp] * dp[10] +
					vp[8 + dvp] * dp[11] +
					vp[7 + dvp] * dp[12] +
					vp[6 + dvp] * dp[13] +
					vp[5 + dvp] * dp[14] +
					vp[4 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples4():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[4 + dvp] * dp[0] +
					vp[3 + dvp] * dp[1] +
					vp[2 + dvp] * dp[2] +
					vp[1 + dvp] * dp[3] +
					vp[0 + dvp] * dp[4] +
					vp[15 + dvp] * dp[5] +
					vp[14 + dvp] * dp[6] +
					vp[13 + dvp] * dp[7] +
					vp[12 + dvp] * dp[8] +
					vp[11 + dvp] * dp[9] +
					vp[10 + dvp] * dp[10] +
					vp[9 + dvp] * dp[11] +
					vp[8 + dvp] * dp[12] +
					vp[7 + dvp] * dp[13] +
					vp[6 + dvp] * dp[14] +
					vp[5 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples5():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[5 + dvp] * dp[0] +
					vp[4 + dvp] * dp[1] +
					vp[3 + dvp] * dp[2] +
					vp[2 + dvp] * dp[3] +
					vp[1 + dvp] * dp[4] +
					vp[0 + dvp] * dp[5] +
					vp[15 + dvp] * dp[6] +
					vp[14 + dvp] * dp[7] +
					vp[13 + dvp] * dp[8] +
					vp[12 + dvp] * dp[9] +
					vp[11 + dvp] * dp[10] +
					vp[10 + dvp] * dp[11] +
					vp[9 + dvp] * dp[12] +
					vp[8 + dvp] * dp[13] +
					vp[7 + dvp] * dp[14] +
					vp[6 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples6():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[6 + dvp] * dp[0] +
					vp[5 + dvp] * dp[1] +
					vp[4 + dvp] * dp[2] +
					vp[3 + dvp] * dp[3] +
					vp[2 + dvp] * dp[4] +
					vp[1 + dvp] * dp[5] +
					vp[0 + dvp] * dp[6] +
					vp[15 + dvp] * dp[7] +
					vp[14 + dvp] * dp[8] +
					vp[13 + dvp] * dp[9] +
					vp[12 + dvp] * dp[10] +
					vp[11 + dvp] * dp[11] +
					vp[10 + dvp] * dp[12] +
					vp[9 + dvp] * dp[13] +
					vp[8 + dvp] * dp[14] +
					vp[7 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples7():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[7 + dvp] * dp[0] +
					vp[6 + dvp] * dp[1] +
					vp[5 + dvp] * dp[2] +
					vp[4 + dvp] * dp[3] +
					vp[3 + dvp] * dp[4] +
					vp[2 + dvp] * dp[5] +
					vp[1 + dvp] * dp[6] +
					vp[0 + dvp] * dp[7] +
					vp[15 + dvp] * dp[8] +
					vp[14 + dvp] * dp[9] +
					vp[13 + dvp] * dp[10] +
					vp[12 + dvp] * dp[11] +
					vp[11 + dvp] * dp[12] +
					vp[10 + dvp] * dp[13] +
					vp[9 + dvp] * dp[14] +
					vp[8 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples8():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[8 + dvp] * dp[0] +
					vp[7 + dvp] * dp[1] +
					vp[6 + dvp] * dp[2] +
					vp[5 + dvp] * dp[3] +
					vp[4 + dvp] * dp[4] +
					vp[3 + dvp] * dp[5] +
					vp[2 + dvp] * dp[6] +
					vp[1 + dvp] * dp[7] +
					vp[0 + dvp] * dp[8] +
					vp[15 + dvp] * dp[9] +
					vp[14 + dvp] * dp[10] +
					vp[13 + dvp] * dp[11] +
					vp[12 + dvp] * dp[12] +
					vp[11 + dvp] * dp[13] +
					vp[10 + dvp] * dp[14] +
					vp[9 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples9():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[9 + dvp] * dp[0] +
					vp[8 + dvp] * dp[1] +
					vp[7 + dvp] * dp[2] +
					vp[6 + dvp] * dp[3] +
					vp[5 + dvp] * dp[4] +
					vp[4 + dvp] * dp[5] +
					vp[3 + dvp] * dp[6] +
					vp[2 + dvp] * dp[7] +
					vp[1 + dvp] * dp[8] +
					vp[0 + dvp] * dp[9] +
					vp[15 + dvp] * dp[10] +
					vp[14 + dvp] * dp[11] +
					vp[13 + dvp] * dp[12] +
					vp[12 + dvp] * dp[13] +
					vp[11 + dvp] * dp[14] +
					vp[10 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples10():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[10 + dvp] * dp[0] +
					vp[9 + dvp] * dp[1] +
					vp[8 + dvp] * dp[2] +
					vp[7 + dvp] * dp[3] +
					vp[6 + dvp] * dp[4] +
					vp[5 + dvp] * dp[5] +
					vp[4 + dvp] * dp[6] +
					vp[3 + dvp] * dp[7] +
					vp[2 + dvp] * dp[8] +
					vp[1 + dvp] * dp[9] +
					vp[0 + dvp] * dp[10] +
					vp[15 + dvp] * dp[11] +
					vp[14 + dvp] * dp[12] +
					vp[13 + dvp] * dp[13] +
					vp[12 + dvp] * dp[14] +
					vp[11 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples11():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[11 + dvp] * dp[0] +
					vp[10 + dvp] * dp[1] +
					vp[9 + dvp] * dp[2] +
					vp[8 + dvp] * dp[3] +
					vp[7 + dvp] * dp[4] +
					vp[6 + dvp] * dp[5] +
					vp[5 + dvp] * dp[6] +
					vp[4 + dvp] * dp[7] +
					vp[3 + dvp] * dp[8] +
					vp[2 + dvp] * dp[9] +
					vp[1 + dvp] * dp[10] +
					vp[0 + dvp] * dp[11] +
					vp[15 + dvp] * dp[12] +
					vp[14 + dvp] * dp[13] +
					vp[13 + dvp] * dp[14] +
					vp[12 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples12():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[12 + dvp] * dp[0] +
					vp[11 + dvp] * dp[1] +
					vp[10 + dvp] * dp[2] +
					vp[9 + dvp] * dp[3] +
					vp[8 + dvp] * dp[4] +
					vp[7 + dvp] * dp[5] +
					vp[6 + dvp] * dp[6] +
					vp[5 + dvp] * dp[7] +
					vp[4 + dvp] * dp[8] +
					vp[3 + dvp] * dp[9] +
					vp[2 + dvp] * dp[10] +
					vp[1 + dvp] * dp[11] +
					vp[0 + dvp] * dp[12] +
					vp[15 + dvp] * dp[13] +
					vp[14 + dvp] * dp[14] +
					vp[13 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples13():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[13 + dvp] * dp[0] +
					vp[12 + dvp] * dp[1] +
					vp[11 + dvp] * dp[2] +
					vp[10 + dvp] * dp[3] +
					vp[9 + dvp] * dp[4] +
					vp[8 + dvp] * dp[5] +
					vp[7 + dvp] * dp[6] +
					vp[6 + dvp] * dp[7] +
					vp[5 + dvp] * dp[8] +
					vp[4 + dvp] * dp[9] +
					vp[3 + dvp] * dp[10] +
					vp[2 + dvp] * dp[11] +
					vp[1 + dvp] * dp[12] +
					vp[0 + dvp] * dp[13] +
					vp[15 + dvp] * dp[14] +
					vp[14 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples14():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[14 + dvp] * dp[0] +
					vp[13 + dvp] * dp[1] +
					vp[12 + dvp] * dp[2] +
					vp[11 + dvp] * dp[3] +
					vp[10 + dvp] * dp[4] +
					vp[9 + dvp] * dp[5] +
					vp[8 + dvp] * dp[6] +
					vp[7 + dvp] * dp[7] +
					vp[6 + dvp] * dp[8] +
					vp[5 + dvp] * dp[9] +
					vp[4 + dvp] * dp[10] +
					vp[3 + dvp] * dp[11] +
					vp[2 + dvp] * dp[12] +
					vp[1 + dvp] * dp[13] +
					vp[0 + dvp] * dp[14] +
					vp[15 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected function compute_pcm_samples15():void {
			var vp:Vector.<Number> = actual_v;	
			var dvp:int = 0;
			for(var i:int = 0; i < 32; i++) {
				var dp:Vector.<Number> = d16[i];
				_tmpOut[i] = (
					vp[15 + dvp] * dp[0] +
					vp[14 + dvp] * dp[1] +
					vp[13 + dvp] * dp[2] +
					vp[12 + dvp] * dp[3] +
					vp[11 + dvp] * dp[4] +
					vp[10 + dvp] * dp[5] +
					vp[9 + dvp] * dp[6] +
					vp[8 + dvp] * dp[7] +
					vp[7 + dvp] * dp[8] +
					vp[6 + dvp] * dp[9] +
					vp[5 + dvp] * dp[10] +
					vp[4 + dvp] * dp[11] +
					vp[3 + dvp] * dp[12] +
					vp[2 + dvp] * dp[13] +
					vp[1 + dvp] * dp[14] +
					vp[0 + dvp] * dp[15]
				) * scalefactor;
				dvp += 16;
			}
		}

		protected static const cos1_64  = 1.0 / (2.0 * Math.cos(Math.PI        / 64.0));
		protected static const cos3_64  = 1.0 / (2.0 * Math.cos(Math.PI * 3.0  / 64.0));
		protected static const cos5_64  = 1.0 / (2.0 * Math.cos(Math.PI * 5.0  / 64.0));
		protected static const cos7_64  = 1.0 / (2.0 * Math.cos(Math.PI * 7.0  / 64.0));
		protected static const cos9_64  = 1.0 / (2.0 * Math.cos(Math.PI * 9.0  / 64.0));
		protected static const cos11_64 = 1.0 / (2.0 * Math.cos(Math.PI * 11.0 / 64.0));
		protected static const cos13_64 = 1.0 / (2.0 * Math.cos(Math.PI * 13.0 / 64.0));
		protected static const cos15_64 = 1.0 / (2.0 * Math.cos(Math.PI * 15.0 / 64.0));
		protected static const cos17_64 = 1.0 / (2.0 * Math.cos(Math.PI * 17.0 / 64.0));
		protected static const cos19_64 = 1.0 / (2.0 * Math.cos(Math.PI * 19.0 / 64.0));
		protected static const cos21_64 = 1.0 / (2.0 * Math.cos(Math.PI * 21.0 / 64.0));
		protected static const cos23_64 = 1.0 / (2.0 * Math.cos(Math.PI * 23.0 / 64.0));
		protected static const cos25_64 = 1.0 / (2.0 * Math.cos(Math.PI * 25.0 / 64.0));
		protected static const cos27_64 = 1.0 / (2.0 * Math.cos(Math.PI * 27.0 / 64.0));
		protected static const cos29_64 = 1.0 / (2.0 * Math.cos(Math.PI * 29.0 / 64.0));
		protected static const cos31_64 = 1.0 / (2.0 * Math.cos(Math.PI * 31.0 / 64.0));
		protected static const cos1_32  = 1.0 / (2.0 * Math.cos(Math.PI        / 32.0));
		protected static const cos3_32  = 1.0 / (2.0 * Math.cos(Math.PI * 3.0  / 32.0));
		protected static const cos5_32  = 1.0 / (2.0 * Math.cos(Math.PI * 5.0  / 32.0));
		protected static const cos7_32  = 1.0 / (2.0 * Math.cos(Math.PI * 7.0  / 32.0));
		protected static const cos9_32  = 1.0 / (2.0 * Math.cos(Math.PI * 9.0  / 32.0));
		protected static const cos11_32 = 1.0 / (2.0 * Math.cos(Math.PI * 11.0 / 32.0));
		protected static const cos13_32 = 1.0 / (2.0 * Math.cos(Math.PI * 13.0 / 32.0));
		protected static const cos15_32 = 1.0 / (2.0 * Math.cos(Math.PI * 15.0 / 32.0));
		protected static const cos1_16  = 1.0 / (2.0 * Math.cos(Math.PI        / 16.0));
		protected static const cos3_16  = 1.0 / (2.0 * Math.cos(Math.PI * 3.0  / 16.0));
		protected static const cos5_16  = 1.0 / (2.0 * Math.cos(Math.PI * 5.0  / 16.0));
		protected static const cos7_16  = 1.0 / (2.0 * Math.cos(Math.PI * 7.0  / 16.0));
		protected static const cos1_8   = 1.0 / (2.0 * Math.cos(Math.PI        / 8.0));
		protected static const cos3_8   = 1.0 / (2.0 * Math.cos(Math.PI * 3.0  / 8.0));
		protected static const cos1_4   = 1.0 / (2.0 * Math.cos(Math.PI / 4.0));
  
		protected static var d:Vector.<Number> =
			Vector.<Number>([
				 0.000000000, -0.000442505,  0.003250122, -0.007003784,
				 0.031082153, -0.078628540,  0.100311279, -0.572036743,
				 1.144989014,  0.572036743,  0.100311279,  0.078628540,
				 0.031082153,  0.007003784,  0.003250122,  0.000442505,
				-0.000015259, -0.000473022,  0.003326416, -0.007919312,
				 0.030517578, -0.084182739,  0.090927124, -0.600219727,
				 1.144287109,  0.543823242,  0.108856201,  0.073059082,
				 0.031478882,  0.006118774,  0.003173828,  0.000396729,
				-0.000015259, -0.000534058,  0.003387451, -0.008865356,
				 0.029785156, -0.089706421,  0.080688477, -0.628295898,
				 1.142211914,  0.515609741,  0.116577148,  0.067520142,
				 0.031738281,  0.005294800,  0.003082275,  0.000366211,
				-0.000015259, -0.000579834,  0.003433228, -0.009841919,
				 0.028884888, -0.095169067,  0.069595337, -0.656219482,
				 1.138763428,  0.487472534,  0.123474121,  0.061996460,
				 0.031845093,  0.004486084,  0.002990723,  0.000320435,
				-0.000015259, -0.000625610,  0.003463745, -0.010848999,
				 0.027801514, -0.100540161,  0.057617188, -0.683914185,
				 1.133926392,  0.459472656,  0.129577637,  0.056533813,
				 0.031814575,  0.003723145,  0.002899170,  0.000289917,
				-0.000015259, -0.000686646,  0.003479004, -0.011886597,
				 0.026535034, -0.105819702,  0.044784546, -0.711318970,
				 1.127746582,  0.431655884,  0.134887695,  0.051132202,
				 0.031661987,  0.003005981,  0.002792358,  0.000259399,
				-0.000015259, -0.000747681,  0.003479004, -0.012939453,
				 0.025085449, -0.110946655,  0.031082153, -0.738372803,
				 1.120223999,  0.404083252,  0.139450073,  0.045837402,
				 0.031387329,  0.002334595,  0.002685547,  0.000244141,
				-0.000030518, -0.000808716,  0.003463745, -0.014022827,
				 0.023422241, -0.115921021,  0.016510010, -0.765029907,
				 1.111373901,  0.376800537,  0.143264771,  0.040634155,
				 0.031005859,  0.001693726,  0.002578735,  0.000213623,
				-0.000030518, -0.000885010,  0.003417969, -0.015121460,
				 0.021575928, -0.120697021,  0.001068115, -0.791213989,
				 1.101211548,  0.349868774,  0.146362305,  0.035552979,
				 0.030532837,  0.001098633,  0.002456665,  0.000198364,
				-0.000030518, -0.000961304,  0.003372192, -0.016235352,
				 0.019531250, -0.125259399, -0.015228271, -0.816864014,
				 1.089782715,  0.323318481,  0.148773193,  0.030609131,
				 0.029937744,  0.000549316,  0.002349854,  0.000167847,
				-0.000030518, -0.001037598,  0.003280640, -0.017349243,
				 0.017257690, -0.129562378, -0.032379150, -0.841949463,
				 1.077117920,  0.297210693,  0.150497437,  0.025817871,
				 0.029281616,  0.000030518,  0.002243042,  0.000152588,
				-0.000045776, -0.001113892,  0.003173828, -0.018463135,
				 0.014801025, -0.133590698, -0.050354004, -0.866363525,
				 1.063217163,  0.271591187,  0.151596069,  0.021179199,
				 0.028533936, -0.000442505,  0.002120972,  0.000137329,
				-0.000045776, -0.001205444,  0.003051758, -0.019577026,
				 0.012115479, -0.137298584, -0.069168091, -0.890090942,
				 1.048156738,  0.246505737,  0.152069092,  0.016708374,
				 0.027725220, -0.000869751,  0.002014160,  0.000122070,
				-0.000061035, -0.001296997,  0.002883911, -0.020690918,
				 0.009231567, -0.140670776, -0.088775635, -0.913055420,
				 1.031936646,  0.221984863,  0.151962280,  0.012420654,
				 0.026840210, -0.001266479,  0.001907349,  0.000106812,
				-0.000061035, -0.001388550,  0.002700806, -0.021789551,
				 0.006134033, -0.143676758, -0.109161377, -0.935195923,
				 1.014617920,  0.198059082,  0.151306152,  0.008316040,
				 0.025909424, -0.001617432,  0.001785278,  0.000106812,
				-0.000076294, -0.001480103,  0.002487183, -0.022857666,
				 0.002822876, -0.146255493, -0.130310059, -0.956481934,
				 0.996246338,  0.174789429,  0.150115967,  0.004394531,
				 0.024932861, -0.001937866,  0.001693726,  0.000091553,
				-0.000076294, -0.001586914,  0.002227783, -0.023910522,
				-0.000686646, -0.148422241, -0.152206421, -0.976852417,
				 0.976852417,  0.152206421,  0.148422241,  0.000686646,
				 0.023910522, -0.002227783,  0.001586914,  0.000076294,
				-0.000091553, -0.001693726,  0.001937866, -0.024932861,
				-0.004394531, -0.150115967, -0.174789429, -0.996246338,
				 0.956481934,  0.130310059,  0.146255493, -0.002822876,
				 0.022857666, -0.002487183,  0.001480103,  0.000076294,
				-0.000106812, -0.001785278,  0.001617432, -0.025909424,
				-0.008316040, -0.151306152, -0.198059082, -1.014617920,
				 0.935195923,  0.109161377,  0.143676758, -0.006134033,
				 0.021789551, -0.002700806,  0.001388550,  0.000061035,
				-0.000106812, -0.001907349,  0.001266479, -0.026840210,
				-0.012420654, -0.151962280, -0.221984863, -1.031936646,
				 0.913055420,  0.088775635,  0.140670776, -0.009231567,
				 0.020690918, -0.002883911,  0.001296997,  0.000061035,
				-0.000122070, -0.002014160,  0.000869751, -0.027725220,
				-0.016708374, -0.152069092, -0.246505737, -1.048156738,
				 0.890090942,  0.069168091,  0.137298584, -0.012115479,
				 0.019577026, -0.003051758,  0.001205444,  0.000045776,
				-0.000137329, -0.002120972,  0.000442505, -0.028533936,
				-0.021179199, -0.151596069, -0.271591187, -1.063217163,
				 0.866363525,  0.050354004,  0.133590698, -0.014801025,
				 0.018463135, -0.003173828,  0.001113892,  0.000045776,
				-0.000152588, -0.002243042, -0.000030518, -0.029281616,
				-0.025817871, -0.150497437, -0.297210693, -1.077117920,
				 0.841949463,  0.032379150,  0.129562378, -0.017257690,
				 0.017349243, -0.003280640,  0.001037598,  0.000030518,
				-0.000167847, -0.002349854, -0.000549316, -0.029937744,
				-0.030609131, -0.148773193, -0.323318481, -1.089782715,
				 0.816864014,  0.015228271,  0.125259399, -0.019531250,
				 0.016235352, -0.003372192,  0.000961304,  0.000030518,
				-0.000198364, -0.002456665, -0.001098633, -0.030532837,
				-0.035552979, -0.146362305, -0.349868774, -1.101211548,
				 0.791213989, -0.001068115,  0.120697021, -0.021575928,
				 0.015121460, -0.003417969,  0.000885010,  0.000030518,
				-0.000213623, -0.002578735, -0.001693726, -0.031005859,
				-0.040634155, -0.143264771, -0.376800537, -1.111373901,
				 0.765029907, -0.016510010,  0.115921021, -0.023422241,
				 0.014022827, -0.003463745,  0.000808716,  0.000030518,
				-0.000244141, -0.002685547, -0.002334595, -0.031387329,
				-0.045837402, -0.139450073, -0.404083252, -1.120223999,
				 0.738372803, -0.031082153,  0.110946655, -0.025085449,
				 0.012939453, -0.003479004,  0.000747681,  0.000015259,
				-0.000259399, -0.002792358, -0.003005981, -0.031661987,
				-0.051132202, -0.134887695, -0.431655884, -1.127746582,
				 0.711318970, -0.044784546,  0.105819702, -0.026535034,
				 0.011886597, -0.003479004,  0.000686646,  0.000015259,
				-0.000289917, -0.002899170, -0.003723145, -0.031814575,
				-0.056533813, -0.129577637, -0.459472656, -1.133926392,
				 0.683914185, -0.057617188,  0.100540161, -0.027801514,
				 0.010848999, -0.003463745,  0.000625610,  0.000015259,
				-0.000320435, -0.002990723, -0.004486084, -0.031845093,
				-0.061996460, -0.123474121, -0.487472534, -1.138763428,
				 0.656219482, -0.069595337,  0.095169067, -0.028884888,
				 0.009841919, -0.003433228,  0.000579834,  0.000015259,
				-0.000366211, -0.003082275, -0.005294800, -0.031738281,
				-0.067520142, -0.116577148, -0.515609741, -1.142211914,
				 0.628295898, -0.080688477,  0.089706421, -0.029785156,
				 0.008865356, -0.003387451,  0.000534058,  0.000015259,
				-0.000396729, -0.003173828, -0.006118774, -0.031478882,
				-0.073059082, -0.108856201, -0.543823242, -1.144287109,
				 0.600219727, -0.090927124,  0.084182739, -0.030517578,
				 0.007919312, -0.003326416,  0.000473022,  0.000015259
			]);
			
		protected static var d16:Vector.<Vector.<Number>> = dSplit();
		protected static function dSplit():Vector.<Vector.<Number>> {
			var dRes:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(32, true);
			var dTmp:Vector.<Number>;
			for (var i:uint = 0; i < 32; i++) {
				var start:uint = i << 4;
				dTmp = new Vector.<Number>(16, true);
				for (var j:uint = 0; j < 16; j++) {
					dTmp[j] = d[start + j];
				}
				dRes[i] = dTmp;
			}
			return dRes;
		}
	}
}
