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
Set.newFrom([-1, 0, 1].collect(_.squared)).sect([1]);
// perform analysis - create separate amp-tracking buffers
(
~seconds_per_beat = 60 / ~bpm;
~analysis_period = ~seconds_per_beat;
~analysis_frames = b.duration / ~seconds_per_beat;
~harmonics = [0, 12, 19, 24];
~subharmonics = ~harmonics[1..].neg;

~sub_indexes = { |root_index|
	~subharmonics.collect(root_index + _).select(_ >= 0).select(_ < ~notes.size);
};
~target_share = { |root_index|
	~harmonics.size - ~sub_indexes.value(root_index).size;
};
~analysis.loadToFloatArray(action: {
	arg array;
	var channels = array.clump(~analysis.numChannels).flop;
	~max_amps = channels.collect({ |amps|
		var period = ~analysis_period * s.sampleRate / s.options.blockSize;
		amps.clump(period).collect(_.maxItem);
	});
	~filtered_amps = ~max_amps.flop.collect({ |channels|
		channels.collect({ |amp, i|
			var prev_amp = if(i == 0, 0, { channels[i-1] });
			var next_amp = if(i == (channels.size - 1), 0, { channels[i+1] });
			var power = channels[i].squared - (0.3 * (prev_amp.squared + next_amp.squared));
			power.max(0).sqrt;
		});
	}).flop;
	~stacked_amps = ~filtered_amps.flop.collect({ |channels|
		var out = FloatArray.fill(~notes.size, 0);
		out.size.do({ |note|
			var partial_indexes = ~harmonics.collect(note+_);
			var target_power = partial_indexes.collect({ |harmonic|
				var sub_indexes = ~sub_indexes.value(harmonic);
				var sub_power;
				sub_power = sub_indexes.collect(out[_].squared).sum;
				(channels[harmonic].squared - sub_power).max(0);
			}).sum;
			var share = ~target_share.value(note);
			var amp = (target_power / share).sqrt;
			out[note] = amp;
		});
		out;
	}).flop;

	"Done generating data, saving to buffers".postln;
	(~pure_env_buffers ++ ~filtered_buffers ++ ~accordion_buffers).do(_.free);
	~pure_env_buffers = ~max_amps[..(~notes.size-1)].collect(Buffer.loadCollection(s, _));
	~filtered_buffers = ~filtered_amps[..(~notes.size-1)].collect(Buffer.loadCollection(s, _));
	~accordion_buffers = ~stacked_amps.collect(Buffer.loadCollection(s, _));
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
SynthDef.new(\accordionPlayer, {
	arg freq, amp_buf, dur;
	var trig = Impulse.kr(dur.reciprocal);
	var index = PulseCount.kr(trig);
	var level = Dbufrd.new(amp_buf, index);
	var env = DemandEnvGen.kr(level, dur);
	var tone = Klang.ar(`[[1,2,3,4], nil, nil], freq * ([-0.05,0.05].midiratio)).sum;
	Out.ar(0, Pan2.ar(tone * env));
}).send;
SynthDef.new(\pureSwell, {
	arg freq, amp, dur;
	var env = EnvGen.kr(Env.triangle(dur), doneAction:2).sqrt * amp;
	Out.ar(0, Pan2.ar(SinOsc.ar(freq, mul: env)));
}).send;

SynthDef.new(\accordionSwell, {
	arg freq, amp, dur;
	var env = EnvGen.kr(Env.triangle(dur), doneAction:2).sqrt * amp;
	var tone = Klang.ar(`[[1,2,3,4], nil, nil], freq * ([-0.05,0.05].midiratio)).sum;
	Out.ar(0, Pan2.ar(tone * env));
}).send;

~play_analysis = { |buf_array, synth, start_measure=0, end_measure=32|
	buf_array.do { |buf, i|
		Synth.new(synth, [
			\freq, ~bins[i].midicps,
			\amp_buf, buf,
			\dur, ~analysis_period
		]);
	};
};
)

~play_analysis.value(~accordion_buffers, \tempoPlayer);
~play_analysis.value(~filtered_buffers, \tempoPlayer);
~play_analysis.value(~pure_env_buffers, \tempoPlayer);
~play_analysis.value(~accordion_buffers, \accordionPlayer);
~play_analysis.value(~pure_env_buffers, \accordionPlayer);
~notes.size
~stacked_amps.size
(
r = Routine {
	~stacked_amps.flop.do { |channels|
		channels.do { |amp, i|
			Synth.new(\accordionSwell, [
				\freq, ~notes[i].midicps,
				\amp, amp,
				\dur, ~analysis_period * 2
			]);
		};
		~analysis_period.yield;
	};
}.play;
)
r.stop;

Synth.new(\accordionPlayer, [\freq:440, \avg_amp: 0.5, \max_amp: 1, \peak_time: 0.5, \dur: 1]);

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
		Klang.ar(`[[1,2,3,4], nil, nil], c * ([-0.05,0.05].midiratio)).sum * amp_out;
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