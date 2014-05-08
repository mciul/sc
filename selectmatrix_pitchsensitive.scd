// server setup

s.options.memSize=1048576;
s.boot;

(
Instr(\decay_dc_k, { arg in, decayTime;
	var coef = (-60/(decayTime*ControlRate.ir)).dbamp;
	LeakDC.kr(in, coef);
});

Instr(\softgate, {
	arg in, gain=200, thresh=0.1;
	(in - thresh).madd(gain).distort.madd(0.5, 0.5);
});

Instr(\matrixmod, { arg in, out_channels, monitor_attack=0.01, monitor_decay=0.5, rank_decay=2, gate_gain=10, gate_thresh=0.6, low_cutoff=2000, high_cutoff=2000, pitch_sensitivity=5;
	var good_ins = LPF.ar(in, low_cutoff);
	var good_in_amps = Amplitude.kr(good_ins, monitor_attack, monitor_decay);
	var bad_in_amps = Amplitude.kr(HPF.ar(in, high_cutoff), monitor_attack, monitor_decay);
	var in_midis = A2K.kr(max(10, ZeroCrossing.ar(good_ins))).lag(monitor_attack).cpsmidi;
	var out_monitors = FbNode(out_channels);
	var out_midis = A2K.kr(max(10, ZeroCrossing.ar(out_monitors))).lag(monitor_attack).cpsmidi;
	//var in_most_good_val, in_most_good_i, in_least_bad_val, in_least_bad_i;
	var out;
	// gate unpleasant signals from input channels
	in = in.madd(Instr(\softgate).kr(good_in_amps - bad_in_amps, gate_gain, gate_thresh));
	out = out_midis.collect({ |out_midi, i|
		var gain = in_midis.collect({ |in_midi, j|
			//var raw_rank = good_in_amp.madd(good_out_amp, bad_out_amps.at(i));
			// a scale of -5 = 12 semitones difference -> -60 db
			var raw_rank = ((0-pitch_sensitivity) * abs(out_midi - in_midi)).dbamp;
			var invert = (i-j-0.5).sign;
			var decaying_rank = Instr(\decay_dc_k).kr(raw_rank, rank_decay);
			Instr(\softgate).kr(decaying_rank, gate_gain, gate_thresh).madd(DC.kr(invert));
		});
		in.madd(gain).sum.softclip;
	});
	out_monitors.write(out);
	out;
});

Instr(\matrixblastr, {
	arg monitor_attack=0.03, monitor_decay=0.5, rank_decay=0.54, gate_gain=100, gate_thresh=-0.03, low_cutoff=801.6, high_cutoff=917.9, pitch_sensitivity=5;
	var feedback_patch = [ 40, 43, 45 ].midicps.reciprocal.collect({|t| FbNode(1, t)});
	var feedback_layer = feedback_patch.collect({|in| LeakDC.ar(in.delay)});
	var middle_layer = Instr(\matrixmod).ar( feedback_layer, 3, monitor_attack, monitor_decay, rank_decay, gate_gain, gate_thresh, low_cutoff, high_cutoff );
	var third_layer = Instr(\matrixmod).ar( middle_layer, 4, monitor_attack, monitor_decay, rank_decay, gate_gain, gate_thresh, low_cutoff, high_cutoff, pitch_sensitivity );
	var front_layer = Instr(\matrixmod).ar( third_layer, 2, monitor_attack, monitor_decay, rank_decay, gate_gain, gate_thresh, low_cutoff, high_cutoff, pitch_sensitivity );
	var feedback_out = Instr(\matrixmod).ar(third_layer, feedback_patch.size, monitor_attack, monitor_decay, rank_decay, gate_gain, gate_thresh, low_cutoff, high_cutoff, pitch_sensitivity );
	feedback_patch.collect({|out, i|
		var signal = feedback_out.at(i);
		out.write(signal.madd(1, SoundIn.ar(0).softclip))
	});
	RLPF.ar(front_layer, Amplitude.kr(front_layer, attackTime:0.05, releaseTime:0.2, mul:1000, add:20), 0.3, 0.2).softclip;
},
#[
		[0.005, 2, \exp, 0],
		[0.005, 2, \exp, 0],
		[0.01, 10, \exp, 0],
		[-10, 100, \lin, 0],
		[-0.1, 0.1, \lin, 0],
		\freq,
		\freq,
		[0, 10, \lin, 0]
]);
)

(Instr(\matrixblastr).gui);

slides:
	arg monitor_attack=0.03, monitor_decay=0.3, rank_decay=3.5, gate_gain=47.6, gate_thresh=-0.1, low_cutoff=516.7, high_cutoff=421.27, pitch_sensitivity=8.92;

({Instr(\matrixblastr).ar}.play)

2.collect({|i| 3.collect({|j| (i-j-0.5).sign}) });

s.scope
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


		