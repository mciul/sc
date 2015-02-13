/*
 * Meat in the House
 *
 * an ambient classic-rock remix
 *
 * Episode 12 of Radio Eyeballsun
 * by Mike Ciul
 *
 */

// do this first to start the server. We need a lot of memory
// for all the delays!

s.quit;
Server.killAll
s.options.memSize=(2**21).postln;
s.recSampleFormat = 'int16';
s.boot;
b.free;
b = Buffer.read( s, "/sample/of/a/rock/song.aiff" );

// Run this block to get the Instr gui, then click "Make a Patch"
(
~blipGate = { |in, trig, gain|
	// Gate the input, and make sure the envelope decays no matter what
	// dynamic the input has at the moment.
	//
	// This is the same strategy used in Radio Eyeballsun Episode 9.
	// I was inspired to revisit it when I learned about ASMR
	// videos on YouTube, and they reminded me of the clipped little
	// noises in some IDM tracks, and the chopped-up music of
	// The Books.
	//
	// Variation to encourage pitches to be more audible:
	// sounds with constant pitch will have a slower decay.
	//
	var amp = Amplitude.ar( in, 0.01 ).max( 0.001 );
	var initial_amp = Latch.ar(amp, trig);
	var delta_amp = ( amp / initial_amp ).max( 0.4 );
	var max_bend = 1, max_sustain = 0.5, min_sustain = 0.2;
	var note, hasFreq, initial_note, sustain;
	var out = DelayN.ar(in, 0.01, 0.01); // allow Amplitude and Pitch to catch up
	#note, hasFreq = K2A.ar(Pitch.kr(in).max(20).cpsmidi);
	initial_note = Latch.ar(note, trig);
	sustain = (max_bend - (initial_note - note).abs).max(0).madd((max_sustain/2 - min_sustain)*hasFreq, min_sustain);
	out * ( Decay2.ar( trig, 0.002, sustain / delta_amp, gain ) );
};

~headPan = { |in, pos, level|
	// use a short delay to simulate the phase delay between the
	// listener's ears. No other spatialization is used -
	// i.e. no reverb
	// My intention is to make the sounds appear very close
	// to the listener's head
	var earTime=0.000625;
	DelayC.ar(Pan2.ar(in, pos, level), earTime, pos.madd(earTime/[2,-2],earTime/2));
};

~dynPan = { |in, depth, level|
	// pan sounds back and forth when they're quiet,
	// but hold them still when they're loud enough to notice
	var maxfreq=100*2/60;
	var thresh=0.05;
	var freq=Amplitude.kr(in).min(thresh).madd(-1/thresh, add:1)*maxfreq;
	~headPan.value(in, SinOsc.kr(freq, 0, depth), level);
};

~select_looper = { |in, maxdelaytime, delaytime, regen, recovery=0.1, thresh=0.5|
	// This was my original looping strategy, but it was
	// too glitchy with the source material used here.
	// It uses a SelectX to switch between new input
	// and delayed loop audio.
	// If you like the glitches, though, it gives a really
	// cool quality to the loops, which sound more like
	// chunked-up samples than echoes
	var monitor_delay = 0.02;
	var loop_delay = delaytime - monitor_delay;
	var node = FbNode(1, maxdelaytime);
	var recycle = node.delay(loop_delay) * regen;
	var in_amp, recycle_amp, choice, out;
	#recycle_amp, in_amp = Amplitude.ar([recycle,in],0.01,[thresh,1]*recovery,[thresh,1]);
	choice = in_amp>recycle_amp;
	out = SelectX.ar(choice.lag(0.01), DelayN.ar([recycle, in], monitor_delay, monitor_delay));
	node.write(out);
	recycle; // out, without monitor delay?
};

~duck_looper = { |in, maxdelaytime, delaytime, regen, recovery=0.1, duck_factor=16|
	// This is what I imagine what most "looping" devices do:
	// repeat the delayed sound forever (when regen=1)
	// but "duck" its level down when new input comes in
	var monitor_delay = 0.01;
	var loop_delay = delaytime - monitor_delay;
	var node = FbNode(1, maxdelaytime);
	var recycle = node.delay(loop_delay) * regen;
	var in_amp, duck, out;
	in_amp = Amplitude.ar(in,0.01,recovery,duck_factor);
	duck = (1-in_amp).max(0);
	out = DelayN.ar([recycle, in], monitor_delay, monitor_delay, [duck,1]).sum;
	node.write(out);
	recycle;
};

~squasher = { |in, squashtime, max_squash|
	// Make envelopes more percussive
	var squash = Amplitude.ar(in, squashtime, squashtime/2, max_squash).min(1);
	in * (1-squash);
};

Instr(\blip, { arg bpm=134.345, gain=0.7, downbeat_regen=1, kick_regen=1, snare_regen=1, tom_regen=1, hihat_regen=1, kick_beat=0, snare_beat=6, tom_beat=9, hihat_beat=10, kick_freq=94.95, snare_freq=3438, tom_freq=1807, hihat_freq=8919, kick_recovery=8, snare_recovery=2, tom_recovery=2, hihat_recovery=1, kick_squash=1, snare_squash=0.1, tom_squash=0.1, hihat_squash=0.1, blip_level=0.6, downbeat_level=0.5, kick_level=2.66, snare_level=4, tom_level=0.8, hihat_level=1.8;
	var sixteenth = 60 / 4 / bpm;
	var max_sixteenth = 60 / 4 / 100;
	// Trigger a gate to let the sample through on downbeats
	var downbeat = Impulse.ar( bpm / 60 / 4, 0 );
	var offbeat_regen = [kick_regen, snare_regen, tom_regen, hihat_regen];
	var offbeat_recovery = [kick_recovery, snare_recovery, tom_recovery, hihat_recovery] * sixteenth;
	var min_beats, max_beats, delays, main_loop, rate, in, amp, initial_amp, attack, chain, outs, mix;
	kick_beat = (kick_beat+8).mod(16);
	min_beats = [8, 32, 16, 0];
	max_beats = [23, 47, 31, 15];
	delays = Slew.kr(Latch.kr(([ kick_beat, snare_beat, tom_beat, hihat_beat ]+min_beats) * sixteenth, downbeat), 0.5, 1);
	main_loop = (64-min_beats[0]) * sixteenth - delays[0];
	rate = 1;

	// loop the samples silently in the background, out of sync with the downbeat
	// (The sample used this time was an entire song. This was actually
	// a mistake but I think it goes with the spirit of the remix.
	// So it doesn't loop that many times)
	in = Mix(PlayBuf.ar(
		b.numChannels,
		b.bufnum,
		rate * BufRateScale.kr( b.bufnum ),
		startPos: 0.911,
		loop: 1
	))/b.numChannels.sqrt;

	in = ~blipGate.value(in, downbeat, gain);

	// The initial delay on the downbeat.
	chain = ~duck_looper.value( in, (64-min_beats[0])*max_sixteenth, main_loop, downbeat_regen );

	// Set up an array of outputs, starting with this delay
	outs = [ chain ];

	// Add four more delays to fill out different beats
	outs = outs ++ delays.collect( {|time, i|
		chain = ~duck_looper.value( chain, max_beats[i] * max_sixteenth, time, offbeat_regen.at(i), offbeat_recovery.at(i) ) * 1.5;
		// Squash sustained notes to make them shorter
		chain = ~squasher.value(chain, sixteenth, [kick_squash, snare_squash, tom_squash, hihat_squash].at(i));
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
	mix = Mix( ~dynPan.value(
		[in] ++ outs,
		[ 0, 0.2, 0.5, 0.5, 0.7, 1.0],
		[ blip_level, downbeat_level, kick_level, snare_level, tom_level, hihat_level ]
	) ).softclip;


	mix;
},
[
		[100, 140, \exp, 0], // bpm
		\amp, //gain
		[0.1, 1, \lin, 0], // downbeat regen
		[0.1, 1, \lin, 0], // kick regen
		[0.1, 1, \lin, 0], // snare regen
		[0.1, 1, \lin, 0], // tom regen
		[0.1, 1, \lin, 0], // hihat regen
		[0, 15, \lin, 1], // kick beat
		[0, 15, \lin, 1], // snare beat
		[0, 15, \lin, 1], // tom beat
		[0, 15, \lin, 1], // hihat beat
		\freq, // kick freq
		\freq, // snare freq
		\freq, // tom freq
		\freq, // hihat freq
		[1, 15, \lin, 0], // kick recovery
		[1, 15, \lin, 0], // snare recovery
		[1, 15, \lin, 0], // tom recovery
		[1, 15, \lin, 0], // hihat recovery
		\amp, // kick squash
		\amp, // snare squash
		\amp, // tom squash
		\amp, // hihat squash
		[0.001, 4, \exp, 0], // blip level
		[0.001, 4, \exp, 0], // downbeat level
		[0.001, 4, \exp, 0], // kick level
		[0.001, 4, \exp, 0], // snare level
		[0.001, 4, \exp, 0], // tom level
		[0.001, 4, \exp, 0], // hihat level
]).gui;
)

// I started recording from here, since the "rec" button on the Patch
// widget kept making things crash
s.prepareForRecord;
s.record;
s.stopRecording;