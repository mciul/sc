b.free;
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav"); // remember to free the buffer later.

(
Instr(\shifted_comb, { arg in, freq=300, shift=100, decaytime=1;
	var pre_shift = FreqShift.ar(in, 0-shift);
	var comb = CombC.ar(pre_shift, 0.2, freq.reciprocal, decaytime);
	FreqShift.ar(comb, shift);
	},
	#[
		\audio,
		\freq,
		[-300, 300, \lin, 0],
		[0.1, 5, \exp, 0]
]);

Instr(\samp_shifted_comb, { arg freq=300, shift=100, decaytime=1;
	var in = PlayBuf.ar(1, b.bufnum, BufRateScale.kr(b.bufnum), loop: 1.0);
	Pan2.ar(Instr(\shifted_comb).ar(in, freq, shift, decaytime), 0);
	},
	#[
		\freq,
		[-300, 300, \lin, 0],
		[0.1, 5, \exp, 0]
]).gui;

Instr(\shifted_res, { arg in, freq=300, shift=100, feedback=0.5;
	var res = FbNode(1, 0.2, interpolation:4);
	var res_time = freq.reciprocal;
	var res_in = res.delay(res_time);
	var post_shift = FreqShift.ar(res_in, shift).softclip;
	var pre_shift = FreqShift.ar(post_shift.madd(feedback, in/2), 0-shift);
	res.write(LeakDC.ar(pre_shift));
	post_shift;
	},
	#[
		\audio,
		[10,344, \exp, 0],
		[-300, 300, \lin, 0],
		[0.5, 1.1, \lin, 0],
		[0, 0.5, \lin, 0]
]);

Instr(\audio_shifted_res, { arg freq=300, shift=100, feedback=0.5;
	//var in = PlayBuf.ar(1, b.bufnum, BufRateScale.kr(b.bufnum), loop: 1.0);
	var in = SoundIn.ar(0);
	Pan2.ar(Instr(\shifted_res).ar(in, freq, shift, feedback), 0);
	},
	#[
		[10,344, \exp, 0],
		[-300, 300, \lin, 0],
		[0.5, 1.1, \lin, 0],
]).gui;
)
s.scope

(22050/64)
