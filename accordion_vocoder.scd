s.quit;
s.boot;
b = Buffer.read( s, "/Users/mciul/Music/GarageBand/quiethours - 3:24:20, 6.17 PM.aif" );
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/han_wang_apology.aiff");
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/langelliott_american_crow.aiff");
~stereo = Buffer.read( s, "/Users/mciul/Music/GarageBand/breathing_together_vocal.aif");
b.numChannels
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/breathing_are3.aiff");

(
Buffer.freeAll;
~createAnalysisBuffer = { |buf|
	~notes = (53..93);
	~bins = (53..121);
	~analysis.free;
	~bpm = 83;
	~analysis = Buffer.alloc(s, buf.numFrames / s.options.blockSize, ~bins.size);
};
b = Buffer.readChannel(
	s,
	"/Users/mciul/Music/GarageBand/breathing_together_vocal.aif",
	channels: [0],
	action: ~createAnalysisBuffer
);
)

// perform analysis - load data
(
{
	var centers = ~bins.midicps;
	var rq = 0.75.midiratio - 1;
	var dur = BufDur.kr(b);
	var play_index = EnvGen.ar(Env.linen(dur, 0, 0, BufFrames.ir(b)), doneAction:2);
	var in = BufRd.ar(1, b, play_index);
	var rec_index = Line.kr(0, BufFrames.ir(~analysis), dur);
	var amps = centers.collect { |c|
		Amplitude.kr(BPF.ar(in, c, rq));
	};
	BufWr.kr(amps, ~analysis, rec_index);
	in;
}.play;
)

// perform analysis - create separate amp-tracking buffers
(
~seconds_per_beat = 60 / ~bpm;
~analysis_period = ~seconds_per_beat;
~analysis_frames = b.duration / ~seconds_per_beat;
~analysis.loadToFloatArray(action: {
	arg array;
	var channels = array.clump(~analysis.numChannels).flop;
	~max_amps = channels.collect({ |amps|
		var period = ~analysis_period * s.sampleRate / s.options.blockSize;
		amps.clump(period).collect(_.maxItem);
	});
	~env_buffers = ~max_amps.collect(Buffer.loadCollection(s, _));
});
)


// check analysis
(
SynthDef.new(\tempoPlayer, {
	arg freq, amp_buf, dur;
	var trig = Impulse.kr(dur.reciprocal);
	var index = PulseCount.kr(trig);
	var level = Dbufrd.new(amp_buf, index);
	var env = DemandEnvGen.kr(level, dur);
	Out.ar(0, Pan2.ar(SinOsc.ar(freq, mul: env)));
}).send;
)
(
~analysis.numChannels.do { |i|
	Synth.new(\tempoPlayer, [
		\freq, ~bins[i].midicps,
		\amp_buf, ~env_buffers[i],
		\dur, ~analysis_period
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