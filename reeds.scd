

s = Server.default;
s.options.memSize=1048576;
//s.options.numWireBufs=128;
s.quit;
Server.default = s.boot;

b = Buffer.alloc(s, 512)

(
Instr.new(\noisy_reed, {
	arg freq=50, excitement=0, avg_width=0.4, width_range=0.1, vibrato_range = 0.5,
	    f1freq=138, f2freq=583, f3freq=2110, f4freq=6000,
	    f1amp=1, f2amp=0.175, f3amp=0.3, f4amp=0.3;
	var lfo = LeakDC.kr(RLPF.kr(WhiteNoise.kr(), freq:6.5, rq:0.1), 0.995);
	var pulsewidth = lfo * excitement * width_range + avg_width;
	var vibrato = (vibrato_range * lfo).midiratio;
	var cutoff = 2000 * lfo * excitement + 2500;
	var tone = LFPulse.ar(freq * vibrato, 0, pulsewidth, excitement);


	var res = LeakDC.ar(LPF.ar(BPF.ar(tone, [f1freq, f2freq, f3freq, f4freq], 0.2, [f1amp, f2amp, f3amp, f4amp]).sum, cutoff));
	FreeVerb2.ar(res, res, 0.5, 0.3, 0.7);
}, #[
	\freq,
	\amp,
	[0,1],
	[0,0.5],
	[0,1],
	\freq,
	\freq,
	\freq,
	\freq,
	\amp,
	\amp,
	\amp,
	\amp
]);

Instr.new(\res_reed, {
	arg in=WhiteNoise.ar, freq=80, excitement=0, min_decay=0.1, decay_range=3,
	    avg_damping=3000, damping_range=3000,
	    vibrato_range = 0.5, tremelo_range = 0.2,
	    f1freq=138, f1amp=1, f2freq=583, f2amp=0.175, f3freq=2110, f3amp=0.3, f4freq=6000, f4amp=0.3;
	var lfo = LeakDC.kr(RLPF.kr(WhiteNoise.kr(), freq:6.5, rq:0.2), 0.995);
	var tremelo = (((lfo - 1) * tremelo_range / 2) + 1) * excitement;
	var decay_time = tremelo * decay_range + min_decay;
	var decay_factor = (-60.dbamp.log/max(1,(freq*decay_time))).exp * -1;
	var vibrato = (vibrato_range * lfo).midiratio;
	var cutoff = (tremelo * damping_range + avg_damping);
	var delay_time = max(0, (freq * vibrato).reciprocal - ControlRate.ir.reciprocal);
	var tone_in = LocalIn.ar(2);
	var tone_lpf = LPF.ar(tone_in, cutoff);
	var tone_leak = LeakDC.ar(tone_lpf);
	var tone_delay = DelayC.ar(tone_leak, 0.1, delay_time, decay_factor);
	var tone = tone_delay.softclip;
	var excitement_amp = max(tremelo, 0);
	var excitement_signal = in * max(excitement_amp, 0); //WhiteNoise.ar(max(excitement_amp, 0)).dup(2);
	var res = BPF.ar(tone, [f1freq, f2freq, f3freq, f4freq], 0.2, [f1amp, f2amp, f3amp, f4amp]).sum;
	// Poll.kr(Impulse.kr(1), min_decay, \min_decay);
	LocalOut.ar(tone + excitement_signal);
	FreeVerb2.ar(res, res, 0.5, 0.3, 0.7);
}, #[
	\ugen,
	\freq,  //freq
	\amp,   //excitement
	[0,5],  //min_decay
	[0,5],  //decay_range
	\freq,  //avg_damping
	\freq,  //damping_range
	[0,1],  //vibrato_range
	\amp,   //tremelo_range
	\freq,  //f1freq
	\amp,   //f1amp
	\freq,  //f2freq
	\amp,   //f2amp
	\freq,  //f3freq
	\amp,   //f3amp
	\freq,  //f4freq
	\amp    //f4amp
]);

Instr(\reed_player, { arg pre_gain=3, excitement_gain=30, res1=43, res2=46, res3=48, res_octave=0, res_decay=1, onset_threshold=0.6, gate_threshold=0.02, room_size=1, sustain=2, min_pitch_lag=0.01, bend_sensitivity=1, max_bend=12, post_gain=1;
	var in = SoundIn.ar([0,1]) * pre_gain;
	var notes = [ res1, res2, res3 ].midicps;
	var res = in.collect({ |chan| CombC.ar(chan, notes.reciprocal, notes.reciprocal, res_decay).sum });
	var freq = ZeroCrossing.ar(LeakDC.ar(RLPF.ar(res, ControlRate.ir*0.75)));
	var amp = Amplitude.kr(in, mul:excitement_gain).softclip;
	var chain = FFT(b, in);
	var note_trig = Onsets.kr(chain, threshold:onset_threshold);
	var note_gate = SetResetFF.kr(note_trig, gate_threshold - amp);
	var note_env = EnvGen.kr(Env([ 0, 1, 0 ], [ 0.01, 0.3 ], releaseNode: 1), note_gate);
	var pitch_lag = min_pitch_lag;
	var pitch = Latch.ar(freq, note_trig);
	var pitch_bend = max(20, freq)/max(20, pitch).ratiomidi;
	var pitch_wobble = LPF.ar((pitch_bend * bend_sensitivity).clip2(max_bend), 6, add:BPF.ar(pitch_bend, 5, 0.1).softclip).midiratio;
	var excitation = (FreeVerb.ar(in, mix:1, room:room_size, mul:excitement_gain)).softclip * (ToggleFF.ar(in) * 2 -1) * note_env;
	//Poll.kr(note_trig, freq, \raw_freq);
	//Poll.kr(note_trig, pitch, \pitch);
	Instr.ar(\res_reed, [ excitation, max(20, VarLag.ar(pitch, pitch_lag, warp:\sin, mul:pitch_wobble)), amp, sustain ] ) * post_gain; // sustain doesn't work
}, #[
		[1, 10, \exp, 0],     //pre_gain
		[1, 50, \exp, 0],     //excitement_gain
		\midi,                //res1
		\midi,                //res2
		\midi,                //res3
		[-2, 2, \lin, 1],     //res_octave
		[0.1, 10, \exp, 0],   //res_decay
		\amp,                 //onset_threshold
		\amp,                 //gate_threshold
		[0,1],                //room_size
		[0,5],                //sustain
		[0.001, 1, \exp, 0],  //min_pitch_lag
		[0.01, 2, \exp, 0],   //bend_sensitivity
		[0.1, 12, \exp, 0],   //max_bend
		[0.1, 10, \exp, 0]    //post_gain
]).gui;
)
75/5

[1,2,3].at([1,2])
[1, 2] * [3, 4]

(
Instr(\clipsin, { arg gain=1, thresh=0.5;
	SinOsc.ar(220).clip2(thresh);
},
	#[
		\amp
	]
).gui;

Instr(\playclipsin, {arg clip;
	Instr.ar(\clipsin, [ 0.5, thresh:clip ]);
	},
	#[
		\amp
	]
).gui;
)
690/20

({
	var ref_freq = 1000;
	var in = SoundIn.ar([0,1]);
	var bins = [ 158, 188, 224, 266, 316, 376, 447, 532, 632, 751, 893, 1061, 1261, 1499, 1782, 2118, 2517, 2992, 3556, 4226 ];
	var vocoder = BPF.ar(bins.collect({in}), bins, 0.05);
	var freq = ZeroCrossing.ar(vocoder);
	var amp = Amplitude.kr(vocoder, 0.01, 16);
	freq = freq * freq / ref_freq;
	SinOsc.ar(freq, 0, amp).sum }.scope;)

1000 / 50.sqrt

141 * 141 / 1000


1000 / 20000
1000 / 0.05.sqrt

4472 * 4472 / 1000



(-60.dbamp.log/(50*1)).exp

0.87096358995608 ** 50

[20, 40, 80, 160, 320, 640, 1280, 5120, 10240] / [1, 1, 1, 1, 1, 1, 1, 1, 2]

(
SynthDef.new("tutorial-SinOsc-stereo", { var outArray;
    outArray = [SinOsc.ar(440, 0, 0.2), SinOsc.ar(442, 0, 0.2)];
    Out.ar(0, outArray)
}).play;
)

Quarks.install("cruciallib")

n=40

Array.geom(n, 20,(1000.log/n).exp).floor
[ 20, 23, 28, 33, 39, 47, 56, 66, 79, 94, 112, 133, 158, 188, 224, 266, 316, 376, 447, 532, 632, 751, 893, 1061, 1261, 1499, 1782, 2118, 2517, 2992, 3556, 4226, 5023, 5970, 7096, 8433, 10023, 11913, 14158, 16827 ]

1000.log/20.log

2

Quarks.gui
