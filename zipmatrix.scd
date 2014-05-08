// server setup

s.options.memSize=1048576;
s.options.numWireBufs=2048;
s.options.numAudioBusChannels=2048;
s.options.numControlBusChannels=16384;
s.boot;
s.options.numWireBufs
s.options.numAudioBusChannels
s.options.numControlBusChannels

(
Instr(\decay_dc_k, { arg in, decayTime;
	var coef = (-60/(decayTime*ControlRate.ir)).dbamp;
	LeakDC.kr(in, coef);
});

Instr(\softgate, {
	arg in, gain=200, thresh=0.1;
	(in - thresh).madd(gain).distort.madd(0.5, 0.5);
});

Instr(\zigzag_delay, {
	arg in, trig, stretch_rate=1, squash_rate=1, min_time=0, max_time=2, lag=0.01;
	var blend = VarLag.kr(ToggleFF.kr(trig).madd(2,-1), lag, warp:\lin);
	var target_time = SetResetFF.kr(blend, 1-blend).madd(max_time-min_time, min_time);
	var up_slew = max(0, 1 - stretch_rate);
	var down_slew = max(0, squash_rate - 1);
	var delay_time = Slew.kr(target_time, up_slew, down_slew);
	DelayC.ar(in, max_time, delay_time, blend);
});

Instr(\matrixmod, { arg in, out_channels, monitor_attack=0.01, monitor_decay=0.5, rank_decay=2, gate_gain=10, gate_thresh=0.6, pitch_sensitivity=5;
	var in_midis = A2K.kr(max(10, ZeroCrossing.ar(in))).lag(monitor_attack).cpsmidi;
	var out_monitors = FbNode(out_channels);
	var out_midis = A2K.kr(max(10, ZeroCrossing.ar(out_monitors))).lag(monitor_attack).cpsmidi;
	var out;
	// gate unpleasant signals from input channels
	out = out_midis.collect({ |out_midi, i|
		var gain = in_midis.collect({ |in_midi, j|
			// a pitch sensitivity value of -5 =
			// 12 semitones difference -> -60 db attenuation
			var raw_rank = ((0-pitch_sensitivity) * abs(out_midi - in_midi)).dbamp;
			//var invert = (i-j-0.5).sign;
			var decaying_rank = Instr(\decay_dc_k).kr(raw_rank, rank_decay);
			Instr(\softgate).kr(decaying_rank, gate_gain, gate_thresh); //* invert;
		});
		in.madd(gain).sum.softclip;
	});
	out.shape.postln;
	out_monitors.write(out);
	out;
});

Instr(\zipmatrix, {
	arg gain=1.8676470588235, monitor_attack=1.4478475623537, monitor_decay=0.16475489724421, rank_decay=15.425328004171, gate_gain=87.254901960784, gate_thresh=0.094117647058824, pitch_sensitivity=19.313725490196, shift= -80.0, stretch=0.5, squash=1.5, fast_mul=0.5625;
	var feedback_times = [1,16,256]* 50.midicps.reciprocal;
	var feedback_patch = feedback_times.collect({|t| FbNode(1, t)});
	var feedback_layer = feedback_patch.collect({|in| LeakDC.ar(in.delay)});
	var add_layer = Instr(\matrixmod).ar( gain * feedback_layer, 3, monitor_attack, monitor_decay, rank_decay, gate_gain, gate_thresh, pitch_sensitivity );
	var note_trig = Coyote.kr(add_layer.at(2), fastMul:fast_mul);
	var note_pitch = A2K.kr(ZeroCrossing.ar(add_layer.at(2))
	).max(20.midicps).cpsmidi.wrap(44,68).midicps;
	var note_latch = Latch.kr(note_pitch, note_trig);
	var add_effect = [
		FreqShift.ar(add_layer.at(0), shift),
		add_layer.at(1).madd(ToggleFF.ar(add_layer.at(1))),
		LeakDC.ar(Instr(\zigzag_delay).ar(add_layer.at(2), note_trig, stretch, squash, 0, feedback_times.wrapAt(-1)))
	];
	var feedback_out_layer = Instr(\matrixmod).ar( gain * add_effect, feedback_patch.size, monitor_attack, monitor_decay, rank_decay, gate_gain, gate_thresh, pitch_sensitivity );
	var audio_out_layer = Splay.ar(add_effect);
	feedback_patch.collect({|out, i|
		var signal = feedback_out_layer.at(i);
		out.write(signal.madd(1, SoundIn.ar(0)).softclip)
	});
	Poll.kr(note_trig, note_latch);
	RLPF.ar(audio_out_layer, Amplitude.kr(audio_out_layer, attackTime:0.05, releaseTime:0.2, mul:1000, add:20), 0.3, 0.2).softclip;
},
#[
		[0.5, 2, \lin, 0],
		[0.005, 2, \exp, 0],
		[0.005, 2, \exp, 0],
		[0.1, 20, \exp, 0],
		[-100, 100, \lin, 0],
		[-0.1, 0.1, \lin, 0],
		[0, 20, \lin, 0],
		[-100, 100, \lin, 0],
		[-2, 1, \lin, 0],
		[1, 4, \lin, 0],
		\amp
]);
)

Instr(\matrixblastr).gui;
s.scope
Patch("matrixblastr",[
	1.8676470588235,
	1.4478475623537,
	0.16475489724421,
	15.425328004171,
	87.254901960784,
	0.094117647058824,
	19.313725490196,
	-97.058823529412,
	0.5,
	1.5,
	0.5625
])

// softer
Patch("matrixblastr",[
	0.98529411764706,
	0.87878878659831,
	0.05396856658104,
	12.531352228865,
	59.803921568627,
	-0.085294117647059,
	10.78431372549,
	-1.9607843137255,
	-1.2,
	3.0,
	0

RunningMax

50.midicps/4
256 * 50.midicps.reciprocal
slides:
	arg monitor_attack=0.03, monitor_decay=0.3, rank_decay=3.5, gate_gain=47.6, gate_thresh=-0.1, low_cutoff=516.7, high_cutoff=421.27, pitch_sensitivity=8.92;

({Instr(\matrixblastr).ar}.play)

3.collect({|i| 2.collect({|j| (i-j-0.5).sign}) });
[ 40, 43, 45, 46 ].midicps.reciprocal

({ControlRate.ir.cpsmidi.poll}.play)
// max integer midi value=76
440.cpsmidi
// A=69
// 76=E
(76.midicps / [ 12, 15, 16, 18, 20, 21, 24 ]).cpsmidi.round.mod(12)
[ 40, 37.960899982692, 36.136862861352, 32.980449991346, 29.117312852698, 28, 25.960899982692, 24.136862861352, 23.292190926655, 20.980449991346, 20.273725722703, 17.117312852698, 16 ].round.mod(12)

[ 3, 1, 2, 2, 1, 3 ]

[ 12, 18, 20 ].collect({|n| [n, n + 3, n + 4]})
(76.midicps/[ [ 12, 15, 16 ], [ 18, 21, 22 ], [ 20, 23, 24 ] ]).cpsmidi.round
[ [ A-02, F+12, E ], [ D-04, B+29, Bb+48 ], [C+14, Bb-28, A-02] ]

// midi values calculated backwards
(76 - [ [ 33, 29, 28 ], [ 26, 23, 22 ], [ 24, 22, 21 ] ]).midiratio.collect({|values| values - values.at(0)})
// subharmonic ratios
(~s_ratios = [[ 11.986456614894, 15.101989002743, 15.999999999823 ],
 [ 17.959392772742, 21.357437666459, 22.627416997687 ],
	[ 20.158736798076, 22.627416997687, 23.972913229722 ] ])

~base_ratios = ~s_ratios.flop.at(0);
~first_ratios = ~s_ratios.flop.at(1);
(~first_ratios - ~first_ratios.round).maxItem
(~first_ratios - ~first_ratios.round).minItem
~adj_first_ratios = ~first_ratios - 0.23

~adj_ratios = ~base_ratios.collect({|n| n + [0, 2.77, 4]})
(76.midicps / ~adj_ratios).cpsmidi
(76.midicps / ~base_ratios.collect({|n| n + [0, 3.23, 3.9]})).cpsmidi

~second_ratios = ~s_ratios.flop.at(2);
(~base_ratios - ~base_ratios.round).mean
((~base_ratios - 0.03) - (~base_ratios - 0.03).round).maxItem
~adj_base_ratios = ~base_ratios - (~base_ratios - ~base_ratios.round).mean

// differences
[ [ 0, 3.1155323878487, 4.0135433849282 ],
  [ 0, 3.3980448937165, 4.6680242249447 ],
  [ 0, 2.4686801996114, 3.8141764316465 ] ]

~s_notes = [ [ 12, 15, 16 ], [ 18, 21, 22 ], [ 20, 23, 24 ]].reciprocal.ratiomidi + 55
~aeolian_s_notes = [ [12, 15, 16], [18, 21], [ 20, 24]].reciprocal.ratiomidi+55
~s_notes.round
~aeolian_s_notes.round
((~aeolian_s_notes - ~aeolian_s_notes.round).flatten.maxItem - (~aeolian_s_notes - ~aeolian_s_notes.round).flatten.minItem)/2

~aeolian_base = ~aeolian_s_notes.flop.at(0)
~
(~aeolian_s_notes - ~aeolian_s_notes.round).flatten.mean
(~aeolian_s_notes - ~aeolian_s_notes.round).flatten.median

{
	var fb=FbNode(4);
	var in = fb.delay(0.1,
}

(SynthDef(\test, {
	var feedback_patch = [0.1, 0.2, 0.3, 0.5].collect({|t| FbNode(1, t)}).postln;
	feedback_patch.delay.postln;
	}))

	50.collect({|n| n.nthPrime})

	[33, 35, 38, 40, 42, 44, 48, 49, 53].mod(12).sort

	[0, 5, 3, 1, 7, 8, 2, 10, 11]+42

	[[0,1,2], [0,4,8]].sum

	[0,5,3,1,7,9,11,12,10,8,7,3].pbind

	// melodic minor/ diminished second thingy
	[ 30, 31, 35, 37, 33, 39, 41, 42, 40, 38, 37 ]
(
SynthDef(\plink, { |freq=440, sustain=1, amp=0.5|
		var sig;
		sig = Pulse.ar(freq, 0.1, amp) * EnvGen.kr(Env.perc(releaseTime:sustain), doneAction:2);
		Out.ar(0, sig !2)}).add;
)

(var midi,dur;
		midi=Pseq([0,1,5,7,3,9,11,12,10,8,7]+30, 1).asStream;
		r = Task({
			var note;
			while {
				note = midi.next;
				note.notNil
			}{
				Synth(\plink, [freq:note.midicps, sustain:0.5]);
				1.yield;
			}
		}).play(quant:TempoClock.default.beats+1.0);
	)

(
		r = Routine({
    [60, 72, 71, 67, 69, 71, 72, 60, 69, 67].do({ |midi| midi.yield });
});

(
Instr(\stereomix, { arg in;
	in.clump(2).sum;
});
)

({Instr(\stereomix).ar(SinOsc.ar([100, 513, 2117, 7892], 0, 0.2))}.play)


		