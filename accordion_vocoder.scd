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
~harmonics = [0, 12, 19, 24, 28];
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

	"Done generating data".postln;
});
)

// check analysis
(
SynthDef.new(\pureSwell, {
	arg freq, amp, dur;
	var env = EnvGen.kr(Env.triangle(dur), doneAction:2).sqrt * amp;
	Out.ar(0, Pan2.ar(SinOsc.ar(freq, mul: env)));
}).send;

SynthDef.new(\accordionSwell, {
	arg freq, amp, dur;
	var env = EnvGen.kr(Env.triangle(dur), doneAction:2).sqrt * amp;
	var tone = Klang.ar(`[[1,2,3,4,5], nil, nil], freq * ([-0.05,0.05].midiratio)).sum;
	Out.ar(0, Pan2.ar(tone * env));
}).send;

~routine_analysis = { |amp_array, synth, start_measure=0, end_measure=40, note_dur=0.5, max_notes=14|
	r = Routine {
		(start_measure..end_measure).do { |measure|
			var min_index = (measure * 4).max(0).min(amp_array[0].size - 1);
			var max_index = (measure * 4 + 3).max(0).min(amp_array[0].size - 1);
			var channel_slices = amp_array.flop[min_index..max_index];
			var channel_sums = channel_slices.flop.collect(_.sum);
			var top_channels = (0..channel_sums.size-1).sort(
				{ |a,b| channel_sums[a] > channel_sums[b] }
			)[0..(max_notes-1)].select({ |i| channel_sums[i] > -60.dbamp }).sort;
			"***** measure ".post;
			measure.postln;
			top_channels.do { |channel|
				"  note ".post;
				~notes[channel].post;
				" - ".post;
				((channel_slices.flop[channel].ampdb / 6).round.asInt + 10).max(0).postln;
			};
			channel_slices.do { |channels|
				top_channels.do { |i|
					Synth.new(synth, [
						\freq, ~notes[i].midicps,
						\amp, channels[i],
						\dur, note_dur * 2
					]);
				};
				note_dur.yield;
			};
		};
	}.play;
}
)

~routine_analysis.value(~stacked_amps, \accordionSwell, 1, 25, ~analysis_period, 15);