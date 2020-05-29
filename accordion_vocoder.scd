s.quit;
s.boot;
b = Buffer.read( s, "/Users/mciul/Music/GarageBand/quiethours - 3:24:20, 6.17 PM.aif" );
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/han_wang_apology.aiff");
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/langelliott_american_crow.aiff");
b = Buffer.read( s, "/Users/mciul/Music/GarageBand/breathing_together_vocal.aif");

b.numChannels
Buffer.freeAll;
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/breathing_are3.aiff");

~notes = (53..93);
~bins = (53..121);
~analysis.free;
~analysis = Buffer.alloc(s, b.numFrames / s.options.blockSize, ~bins.size);

// perform analysis - load data
(
{
	var centers = ~bins.midicps;
	var rq = 0.75.midiratio - 1;
	var dur = b.numFrames * BufRateScale.ir(b) / SampleRate.ir;
	var play_index = EnvGen.ar(Env.linen(dur, 0, 0, BufFrames.ir(b)), doneAction:2);
	var in = BufRd.ar(b.numChannels, b, play_index).sum;
	var rec_index = EnvGen.ar(Env.linen(dur, 0, 0, BufFrames.ir(~analysis)));
	var amps = centers.collect { |c|
		Amplitude.kr(BPF.ar(in, c, rq));
	};
	BufWr.kr(amps, ~analysis, rec_index);
	in;
}.play;
)
FloatArray

// perform analysis - find average and max amp
(
~analysis.loadToFloatArray(action: {
	arg array;
	var channels = array.clump(~analysis.numChannels).flop;
	~avg_amps = channels.collect(_.mean);
	~max_amps = channels.collect(_.maxValue({|amp| amp}));
	~peak_times = channels.collect(_.maxIndex({|amp| amp})) / ~analysis.numFrames;
});
)

// check analysis
(
SynthDef.new(\partialPlayer, {
	arg freq, avg_amp, max_amp, peak_time, dur;
	var min_amp = ((2 * avg_amp) - max_amp).max(0);
	var env = EnvGen.kr(
		Env.new([0, min_amp, max_amp, min_amp, 0], [0, peak_time, 1-peak_time, 0]),
		timeScale: dur,
		doneAction: 2);
	Out.ar(0, Pan2.ar(SinOsc.ar(freq, mul: env)));
}).send;
SynthDef.new(\sustainPlayer, {
	arg freq, avg_amp, max_amp, peak_time, dur;
	var sustain = ((2 * avg_amp) - max_amp) / max_amp;
	var plateau = sustain.max(0);
	var pre_plateau = peak_time * (1 - plateau);
	var post_plateau = peak_time + (plateau / (1 - peak_time));
	var silence = sustain.neg.max(0);
	var pre_silence = silence * peak_time;
	var post_silence = peak_time + ((1 - silence) * (1 - peak_time));
	var levels = [0,0,max_amp, max_amp,0];
	var times = [pre_silence, pre_plateau, post_plateau, post_silence];
	var env = EnvGen.kr(
		Env.new(levels, times),
		timeScale: dur,
		doneAction: 2);
	Out.ar(0, Pan2.ar(SinOsc.ar(freq, mul: env)));
}).send;)

(
~analysis.numChannels.do { |i|
	Synth.new(\sustainPlayer, [
		\freq, ~bins[i].midicps,
		\avg_amp, ~avg_amps[i],
		\max_amp, ~max_amps[i],
		\peak_time, ~peak_times[i],
		\dur, 2
	]);
}
)

Synth.new(\partialPlayer, [\freq:440, \avg_amp: 0.5, \max_amp: 1, \peak_time: 0.5, \dur: 1]);

(
{
	var centers = notes.midicps;
	var rq = 1.midiratio - 1;
	var in = PlayBuf.ar(b.numChannels,b).sum;
	var amps = centers.collect { |c|
		Amplitude.kr(BPF.ar(in, c, rq));
	};
	var synths;
	var orig_amps = amps.copy;
	/*
	[12, 19, 24, 28].collect { |harmonic|
		(centers.size-harmonic).do { |i|
			amps[i+harmonic] = amps[i+harmonic] - orig_amps[i];
		};
	};

	(centers.size-1).do { |i|
		amps[i] = amps[i] - (orig_amps[i+1] * 0.5);
		amps[i+1] = amps[i+1] - (orig_amps[i] * 0.5);
	};
	*/
	synths = centers.collect { |c, i|
		var thresh = -40.dbamp;
		var amp_out = Lag.kr(max(0, amps[i] - thresh), 0.2);
		Poll.kr(SetResetFF.kr(amps[i] - thresh, (thresh/32) - orig_amps[i]), amps[i].ampdb.round, i);
		//Poll.kr(SetResetFF.kr(amps[i] - (thresh * 2), amps[i] - thresh), amps[i].ampdb.round, i);
		//Poll.kr(SetResetFF.kr(amps[i] - (thresh * 4), amps[i] - thresh), amps[i].ampdb.round, i);
		Poll.kr(SetResetFF.kr(amps[i] - (thresh * 8), orig_amps[i] - thresh), amps[i].ampdb.round, i);
		Klang.ar(`[[1,2,3,4,5], nil, nil], c * ([-0.05,0.05].midiratio)).sum * amp_out;
		//SinOsc.ar(c, 0, amp_out * 0.5);
	};
	Pan2.ar(synths.sum);
}.play
)

"We".postln
"Are".postln
"breath-".postln
"-ing".postln
"To-".postln;
"ge-".postln;
"-ther".postln;