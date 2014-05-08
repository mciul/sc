// server setup

s.options.memSize=1048576;
s.boot;

// Instr definitions
(
Instr(\softgate, {
	arg in, gain=200, thresh=0.5;
	(in - thresh).madd(gain).distort.madd(0.5, 0.5);
});

Instr(\stereodrone, { arg gain=1, limit_level=0.5, resbustdecay=0.01, resbustmix=0.24, rate=0.9, depth=0.83, post_gain=0.7;
	var in = SoundIn.ar([0,1]) * gain;
	var measure = 2;
	var notes = [ 48, 43, 46, 51, 41 ].midicps;
	var beats = [1, 0.5];
	var times = beats * measure - ControlRate.ir.reciprocal;
	var decay = (-60 * beats / 2).dbamp;
	var feedback_monitor = FbNode(2);
	var boring_gate = FbNode(2);
	var highbustfreq = ZeroCrossing.ar(BPF.ar(feedback_monitor.delay, 5000, 2)).lag(measure);
	var delays = CombN.ar(Notch.ar(in.madd(boring_gate.delay), highbustfreq), [measure * 2, measure/2], [measure * 2, measure/2], measure * 3, add:in);
	var res = delays.collect({|chain, i| CombC.ar(chain, notes.reciprocal, notes.reciprocal, measure)});
	var filtered = LeakDC.ar(LPF.ar(res, 2000)).flop;
	var amp = filtered.collect({ |band| RLPF.ar(Amplitude.ar(band), (measure/[1,8]).reciprocal, 0.5) });
	var val, index, selection, out, selectednote, resbustnote, resbustfreq;
	# val, index = ArrayMax.ar(amp).flop;
	selection = ([index.at(0), LastValue.ar(index.at(1))] + 1).wrap(0, notes.size - 1);
	selectednote = Select.ar(selection, DC.ar(notes)).cpsmidi;
	resbustnote = BPF.ar(selectednote, rate, 0.2, depth, selectednote.lag(measure * 8));
	resbustfreq = resbustnote.midicps;
	boring_gate.write(Instr(\softgate).ar((selectednote - resbustnote).abs), 200, 0.1);
	amp = amp.collect({ |stereo, i| [stereo.at(0) + 0.5, stereo.at(1) * stereo.at(1) * 1800].softclip});
	out = SelectX.ar(selection.lag(measure/[4,16]), (filtered * amp));
	out = CombC.ar(out, delaytime:resbustfreq.reciprocal, decaytime: resbustdecay, mul:-1 * resbustmix, add:out);
	feedback_monitor.write(out);
	"out: ".post;
	out.postln;
	Limiter.ar(out, 0.5, [measure/2, measure]) * post_gain;
},
	#[
		\amp,                //gain
		\amp,                //limit_level
		[0.001, 1, \exp, 0], //resbustdecay
		\amp,                //resbustmix
		[0.5, 20, \exp, 0],  //rate
		[0, 5],              //depth
		\amp                 //post_gain
	]
);
Instr.new(\res_reed, {
	arg in=WhiteNoise.ar, freq=80, excitement=0, min_decay=0.1, decay_range=3,
	    avg_damping=3000, damping_range=3000,
	    vibrato_range = 0.5, tremelo_range = 0.2,
	    f1freq=138, f1amp=0.5, f2freq=583, f2amp=0.175, f3freq=2110, f3amp=0.3, f4freq=6000, f4amp=0.3;
	var lfo = LeakDC.kr(RLPF.kr(WhiteNoise.kr(), freq:6.5, rq:0.2), 0.995);
	var tremelo = (((lfo - 1) * tremelo_range / 2) + 1) * excitement;
	var decay_time = tremelo * decay_range + min_decay;
	var decay_factor = (-60.dbamp.log/max(1,(freq*decay_time))).exp * -1;
	var vibrato = (vibrato_range * lfo).midiratio;
	var cutoff = (tremelo * damping_range + avg_damping);
	var delay_time = max(0, (freq * vibrato).reciprocal - ControlRate.ir.reciprocal);
	var air_column = FbNode(2, 0.1, interpolation:4);
	var tone_in = air_column.delay(delay_time);
	var tone_lpf = LPF.ar(tone_in, cutoff);
	var tone_leak = LeakDC.ar(tone_lpf, mul:decay_factor);
	var tone = tone_leak.softclip;
	var excitement_amp = max(tremelo, 0);
	var excitement_signal = in * max(excitement_amp, 0); //WhiteNoise.ar(max(excitement_amp, 0)).dup(2);
	var res;
	var f_freqs = [f1freq, f2freq, f3freq, f4freq];
	var f_amps = [f1amp, f2amp, f3amp, f4amp];
	f_amps = f_amps * f_freqs.collect({ |f_freq| Instr(\softgate).kr(f_freq - freq, thresh:0) } );
	res = BPF.ar(tone, f_freqs, 0.2, f_amps).sum;
	air_column.write(tone + excitement_signal);
	FreeVerb2.ar(res.at(0), res.at(1), 0.5, 0.3, 0.7).postln;
}, #[
	\audio,
	\audio,  //freq
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

Instr(\reed_player, { arg pre_gain=3, excitement_gain=30, res1=43, res2=46, res3=48, res_octave=0, res_decay=1, fast_mul=1, onset_threshold=0.05, pitch_threshold=0.5, gate_threshold=0.02, room_size=1, sustain=2, min_pitch_lag=0.01, bend_sensitivity=1, max_bend=1, post_gain=1;
	var in = SoundIn.ar([0,1]) * pre_gain;
	var notes = [ res1, res2, res3 ].midicps;
	var res = in.collect({ |chan| CombC.ar(chan, notes.reciprocal, notes.reciprocal, res_decay).sum });
	//var chain = FFT({LocalBuf(512)}!2, in);
	var freq, has_freq, amp, note_trig, note_gate, note_env, pitch, pitch_bend, pitch_wobble, pitch_lag, excitation;
	//freq = ZeroCrossing.ar(LeakDC.ar(RLPF.ar(res, ControlRate.ir*0.75)));
	#freq, has_freq = in.collect({|channel| Tartini.kr(channel, n:512)}).flop;
	amp = Amplitude.kr(in, mul:excitement_gain).softclip;
	//note_trig = Onsets.kr(chain, threshold:onset_threshold);
	note_trig = Coyote.kr(in, fastMul:fast_mul, thresh:onset_threshold) * (has_freq - pitch_threshold);
	note_gate = SetResetFF.kr(note_trig, gate_threshold - amp);
	note_env = EnvGen.kr(Env([ 0, 1, 0 ], [ 0.01, 0.3 ], releaseNode: 1), note_gate);
	pitch = Latch.kr(freq, note_trig);
	pitch_bend = max(20, freq)/max(20, pitch).ratiomidi;
	pitch_wobble = LPF.kr((pitch_bend * bend_sensitivity).clip2(max_bend), 6, add:BPF.kr(pitch_bend, 5, 0.1).softclip).midiratio;
	pitch_lag = max(20, VarLag.kr(pitch, min_pitch_lag, warp:\sin, mul:pitch_wobble));
	excitation = ((FreeVerb.ar(in.madd(excitement_gain).softclip, mix:1, room:room_size)).softclip).madd(note_env);
	//Poll.kr(note_trig, freq, \raw_freq);
	//Poll.kr(Impulse.kr(1), pitch, \pitch);
	Instr.at(\res_reed).ar(excitation, pitch_lag, amp, sustain) * post_gain;
}, #[
		[1, 10, \exp, 0],     //pre_gain
		[1, 50, \exp, 0],     //excitement_gain
		\midi,                //res1
		\midi,                //res2
		\midi,                //res3
		[-2, 2, \lin, 1],     //res_octave
		[0.1, 10, \exp, 0],   //res_decay
		[0.01, 2, \exp, 0],   //fast_mul
		\amp,                 //onset_threshold
		[0,1],                //pitch_threshold
		\amp,                 //gate_threshold
		[0,1],                //room_size
		[0,5],                //sustain
		[0.001, 1, \exp, 0],  //min_pitch_lag
		[0.01, 2, \exp, 0],   //bend_sensitivity
		[0.1, 12, \exp, 0],   //max_bend
		[0.1, 10, \exp, 0]    //post_gain
]);

Instr(\eight_chan_recorder, { |bufnum, audio_in, instr1, instr2, instr3| "bufnum: ".post; bufnum.postln; DiskOut.ar(bufnum, audio_in ++ instr1 ++ instr2 ++ instr3); instr1 + instr2 + instr3; } );

Instr(\soundin_passthrough, { SoundIn.ar([0,1]); });

Instr(\mouse_conductor, {
	arg lag_time, gain, first_node, last_node;
	var trig = MouseY.kr(-1, 0.01);
	var seq = Dseq(0.dup(first_node) ++ 1.dup(last_node - first_node + 1) ++ [0]);
	Demand.kr(trig, 0, seq).lag(lag_time);
});
)

x = {Instr.ar(\reed_player)}.scope;
x.free;

x = {Instr(\stereodrone).ar(1, 0.5, 0.17, 1, 3.05, 0.83, 0.7)}.scope;

Instr(\reed_player).gui;
Instr(\stereodrone).gui;

/*
pre_gain=3, excitement_gain=30, res1=43, res2=46, res3=48, res_octave=0, res_decay=1, fast_mul=1, onset_threshold=0.05, pitch_threshold, gate_threshold=0.02, room_size=1, sustain=2, min_pitch_lag=0.01, bend_sensitivity=1, max_bend=1, post_gain=1;
        [1, 10, \exp, 0],     //pre_gain
		[1, 50, \exp, 0],     //excitement_gain
		\midi,                //res1
		\midi,                //res2
		\midi,                //res3
		[-2, 2, \lin, 1],     //res_octave
		[0.1, 10, \exp, 0],   //res_decay
        [0.01, 2, \exp, 0],   //fast_mul
		\amp,                 //onset_threshold
		[0,1],                //pitch_threshold
		\amp,                 //gate_threshold
		[0,1],                //room_size
		[0,5],                //sustain
		[0.001, 1, \exp, 0],  //min_pitch_lag
		[0.01, 2, \exp, 0],   //bend_sensitivity
		[0.1, 12, \exp, 0],   //max_bend
		[0.1, 10, \exp, 0]    //post_gain
*/

// Playing
b = Buffer.alloc(s, 65536, 8);
b.write(sampleFormat:"int16", numFrames:0, startFrame:0, leaveOpen:true);
b.bufnum

( x = {
	//var trig = MouseY.kr(-1, 0.01);
	//var count = Poll.kr(trig, PulseCount.kr(trig));
	var drone_level = Instr.ar(\mouse_conductor, [8, 1, 0, 2]);
	var reed1_level = Instr.ar(\mouse_conductor, [4, 3, 1, 4]);
	var reed2_level = Instr.ar(\mouse_conductor, [2, 3, 2, 3]);
	var bed = Instr.ar(\stereodrone, [drone_level]);
	var solo1 = Instr.ar(\reed_player, [reed1_level, 10, 43, 46, 55, -1, 1, 2, 0.01, 0.7, 0.02, 1, 0.8, 0.01, 1, 12]);
	var solo2 = Instr.ar(\reed_player, [reed2_level, 10, 48, 51, 60, 0, 5, 0.85, 0, 0.85, 0.005, 1, 2, 0.01, 0.05, 1]);
	Instr.ar(\eight_chan_recorder, [b.bufnum, SoundIn.ar([0,1]), bed, solo1, solo2]);
	// bed + solo1 + solo2;
}.play)

x.free;
b.free;

MultiChanRecorder
// Testing
(
y = {
	var trig = MouseY.kr(-1, 0.01);
	var seq = Dseq([1,0]);
	var level = Demand.kr(trig, 0, seq).lag(4);
	Instr.ar(\reed_player, [level * 3])
}.scope;
)
y.free;

(
Instr(\delay_test, {
	var in = SoundIn.ar([0,1]);
	var measure = 2;
	var beats = [1, 0.5];
	var notes = [ 48, 43, 46, 51, 41 ].midicps;
	var times = beats * measure - ControlRate.ir.reciprocal;
	var decay = (-60 * beats / 2).dbamp;
	var feedback_monitor = FbNode(2);
	var highbustfreq = ZeroCrossing.ar(BPF.ar(feedback_monitor.delay, 5000, 2)).lag(measure);
	var delays = CombN.ar(Notch.ar(in, highbustfreq), [measure * 2, measure/2], [measure * 2, measure/2], measure * 3, add:in);
	var res = delays.collect({|chain, i| CombC.ar(chain, notes.reciprocal, notes.reciprocal, measure)}).postln;
	feedback_monitor.write(delays);
	Limiter.ar(delays, 0.5, [measure/2, measure]);
});
)

x = Patch(\delay_test).play;

b = Buffer.alloc(s, 65536, 8);
b.write(sampleFormat:"int16", numFrames:0, startFrame:0, leaveOpen:true);
(
x = {
	var sound = SoundIn.ar([0,1]);
	var solo1 = Instr.ar(\reed_player, [1, 30, 43, 46, 55, -1, 1, 2, 0.01, 0.7, 0.02, 1, 0.8, 0.01, 1, 12]);
	Instr.ar(\eight_chan_recorder, [b.bufnum, sound, solo1, solo1, solo1])
}.play;
)
x.free;
b.free;

x = Patch(\stereo_test, [5.5]).play;
x.free;
"".postln

[ [1, 2], [3, 4], [5, 6] ] * [ 0, 1]