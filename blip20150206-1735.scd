
s.options.memSize=1048576;
s.recSampleFormat = 'int16';
s.boot;
b.free;
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/mono/silvermountain_theme_mono.aiff" );

s.prepareForRecord;
s.record;
s.stopRecording;

// look up some prime numbers for the reverb
(200..240).collect( _.nthPrime );
(
var next = 0.05 * 44100;
next.asInteger.nextPrime;
( { var p = next.asInteger.nextPrime; next = p * 1.2; p } ).dup( 6 );
)
/*
0.03: [ 1327, 1597, 1931 ]
0.05: [ 2207, 2657, 3191 ]
0.07: [ 3089, 3709, 4451 ]
*/
(112/60/4).reciprocal

// This is the actual patch.
// TODO: compression on delays, so dynamics even out as they cycle?
(
Instr(\blip, { arg bpm=105.59, gain=0.7, downbeat_decay=4, kick_decay=8, snare_decay=17, tom_decay=16, hihat_decay=2, kick_beat=2, snare_beat=11, tom_beat=6, hihat_beat=8, kick_freq=57, snare_freq=6487, tom_freq=1737, hihat_freq=8919, reverb_decay=1.5, reverb_wet=0.2;
	var sixteenth = 60 / 4 / bpm;
	var max_sixteenth = 60 / 4 / 100;
	// Trigger a gate to let the sample through on downbeats
	var downbeat = Impulse.ar( bpm / 60 / 4, 0 );
	var offbeat_decay = [kick_decay, snare_decay, tom_decay, hihat_decay];
	var min_beats, max_beats, delays, comb, rate, in, amp, initial_amp, attack, chain, outs, mix;
	kick_beat = (kick_beat+8).mod(16);
	min_beats = [8, 32, 16, 0];
	max_beats = [23, 47, 31, 15];
	delays = Slew.kr(Latch.kr(([ kick_beat, snare_beat, tom_beat, hihat_beat ]+min_beats) * sixteenth, downbeat), 0.5, 1);
	comb = (32-min_beats[0]-delays[0]) * sixteenth;
	Poll.ar(downbeat, delays/sixteenth, "delays");
	Poll.ar(downbeat, offbeat_decay, "offbeat decays");
	rate = 1;

	// loop the samples silently in the background, out of sync with the downbeat
	in = Mix(PlayBuf.ar(
		b.numChannels,
		b.bufnum,
		rate * BufRateScale.kr( b.bufnum ),
		startPos: 0.911,
		loop: 1
	))/b.numChannels.sqrt;

	// Gate the sample, and make sure the envelope decays no matter what
	// dynamic the sample has at the moment.
	//
	// Quieter sounds will have a slower decay.
	//
	amp = Amplitude.ar( in ).max( 0.001 );
	initial_amp = Latch.ar(amp, downbeat);
	attack = ( amp / initial_amp ).max( 0.4 );
	in = in * ( Decay2.ar( downbeat, 0.002, 0.3 / attack, gain ) );

	// The initial delay on the downbeat.
	chain = CombN.ar( in, (32-min_beats[0])*max_sixteenth, comb, comb * downbeat_decay );
	Poll.ar(downbeat, (32-min_beats[0])*max_sixteenth - comb, "comb headroom");

	// Set up an array of outputs, starting with this delay
	outs = [ chain ];

	// Add four more delays to fill out different beats
	//
	// These delays have just a few repeats, also controlled by MouseX
	outs = outs ++ delays.collect( {|time, i|
		chain = CombN.ar( chain, max_beats[i] * max_sixteenth, time, time * offbeat_decay.at(i), 1.5);
		Poll.ar(downbeat, max_beats[i] * max_sixteenth - time, "offbeat headroom");
		// Filter each delay to give it a different "drum" sound
		Resonz.ar(
			chain,
			[kick_freq, snare_freq, tom_freq, hihat_freq].at(i),
			[ 0.4, 0.1, 0.2, 0.1 ].at(i)
		);
	});

	// Cheap-ass stereo effect: pan all the delays back and forth across the field.
	//
	// use gentle distortion as a limiter
	mix = Mix( Pan2.ar(
		[in] ++ outs,
		FSinOsc.ar(
			[ 0, 1/16, 1/8, 1/4, 1/2 ]/sixteenth,
			[ 0, 0.5, 1, 1.5, 0] * pi,
			[ 0, 0.3, 0.3, 0.5, 0.7]
		),
		[ 1, 1.5, 2, 1, 4 ]
	) ).softclip;

	// add some stereo reverb
	[ 2207, 2657, 3191, 3833, 4603 ].do( { |samples, i|
		var time = samples / SampleRate.ir;
		mix = CombN.ar( mix.rotate, time, time, reverb_decay / 3.sqrt, mul: reverb_wet.neg, add: mix );
	} );
	mix;
},
[
		[100, 140, \exp, 0], // bpm
		\amp, //gain
		[1, 36, \lin, 0], // downbeat decay
		[1, 18, \lin, 0], // kick decay
		[1, 18, \lin, 0], // snare decay
		[1, 18, \lin, 0], // tom decay
		[1, 18, \lin, 0], // hihat decay
		[0, 15, \lin, 1], // kick beat
		[0, 15, \lin, 1], // snare beat
		[0, 15, \lin, 1], // tom beat
		[0, 15, \lin, 1], // hihat beat
		\freq, // tom
		\freq, // snare freq
		\freq, // kick freq
		\freq, // hihat
		[0, 4, \lin, 0], // reverb decay
		\amp, // reverb wet
]).gui;
)

