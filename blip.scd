2**21

s.options.memSize=(2**21).postln;
s.recSampleFormat = 'int16';
s.boot;
s.quit;
b.free;
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/backyard 20060801 1425.aiff" );

b.numChannels
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
60/4/112

play{l=LFSaw;a=Decay.ar(Impulse.ar(1/8),0.2,l.ar(l.kr(2/25,0,88,176)));[16,10,4,3].do({|t|a=CombN.ar(a,8,t/8+[3,4],16,2,a)});a}//#sctweets

8,t/8+[3,4]
d=t/8+[3,4];d,d
// This is the actual patch.
(
~blipGate = { |in, trig, gain|
	// Gate the input, and make sure the envelope decays no matter what
	// dynamic the input has at the moment.
	//
	// sounds with constant pitch will have a slower decay.
	//
	var amp = Amplitude.ar( in ).max( 0.001 );
	var initial_amp = Latch.ar(amp, trig);
	var delta_amp = ( amp / initial_amp ).max( 0.4 );
	var max_bend = 1, max_sustain = 0.5, min_sustain = 0.2;
	var note, hasFreq, initial_note, sustain;
	#note, hasFreq = K2A.ar(Pitch.kr(in).max(20).cpsmidi);
	initial_note = Latch.ar(note, trig);
	sustain = (max_bend - (initial_note - note).abs).max(0).madd((max_sustain/2 - min_sustain)*hasFreq, min_sustain);
	in = in * ( Decay2.ar( trig, 0.002, sustain / delta_amp, gain ) );
};

~headPan = { |in, pos, level|
	var earTime=0.000625;
	DelayC.ar(Pan2.ar(in, pos, level), earTime, pos.madd(earTime/[2,-2],earTime/2));
};

~dynPan = { |in, depth, level|
	var maxfreq=100*2/60;
	var thresh=0.05;
	var freq=Amplitude.kr(in).min(thresh).madd(-1/thresh, add:1)*maxfreq;
	~headPan.value(in, SinOsc.kr(freq, 0, depth), level);
};

~looper = { |in, maxdelaytime, delaytime, regen, thresh=0.1|
	var node = FbNode(1, maxdelaytime);
	var recycle = node.delay(delaytime) * regen;
	// give a slight bias to new sounds by multiplying * 1.1
	var amps = Amplitude.ar([recycle,in],0.001,0.1,[thresh,1]);
	var out = SelectX.ar(amp[1]>amp[0], [recycle, in]);
	node.write(out);
	//recycle; // + in?
};

~squasher = { |in, squashtime, max_squash|
	var squash = Amplitude.ar(in, squashtime, 0.01, max_squash).min(1);
	in * (1-squash);
};

~reverb = { |in, wet, decay|
	// add some stereo reverb
	var times = [ 2207, 2657, 3191, 3833, 4603 ] / SampleRate.ir;
	times.do( { |time, i|
		in = CombN.ar( in.rotate, time, time, decay / times.size.sqrt, mul: wet.neg, add: in );
	} );
	in;
};

Instr(\blip, { arg bpm=104.59, gain=0.7, downbeat_regen=1, kick_decay=8, snare_decay=17, tom_decay=16, hihat_decay=2, kick_beat=12, snare_beat=11, tom_beat=6, hihat_beat=10, kick_freq=57, snare_freq=6487, tom_freq=1737, hihat_freq=8919, blip_level=0.75, downbeat_level=0.75, kick_level=1.5, snare_level=2, tom_level=1, hihat_level=4;
	var sixteenth = 60 / 4 / bpm;
	var max_sixteenth = 60 / 4 / 100;
	// Trigger a gate to let the sample through on downbeats
	var downbeat = Impulse.ar( bpm / 60 / 4, 0 );
	var offbeat_decay = [kick_decay, snare_decay, tom_decay, hihat_decay];
	var min_beats, max_beats, delays, main_loop, rate, in, amp, initial_amp, attack, chain, outs, mix;
	kick_beat = (kick_beat+8).mod(16);
	min_beats = [8, 32, 16, 0];
	max_beats = [23, 47, 31, 15];
	delays = Slew.kr(Latch.kr(([ kick_beat, snare_beat, tom_beat, hihat_beat ]+min_beats) * sixteenth, downbeat), 0.5, 1);
	main_loop = (64-min_beats[0]) * sixteenth - delays[0];
	rate = 1;

	// loop the samples silently in the background, out of sync with the downbeat
	in = Mix(PlayBuf.ar(
		b.numChannels,
		b.bufnum,
		rate * BufRateScale.kr( b.bufnum ),
		startPos: 0.911,
		loop: 1
	))/b.numChannels.sqrt;

	in = ~blipGate.value(in, downbeat, gain);

	// The initial delay on the downbeat.
	chain = ~looper.value( in, (64-min_beats[0])*max_sixteenth, main_loop, downbeat_regen );

	// Set up an array of outputs, starting with this delay
	outs = [ chain ];

	// Add four more delays to fill out different beats
	//
	// These delays have just a few repeats, also controlled by MouseX
	outs = outs ++ delays.collect( {|time, i|
		chain = CombN.ar( chain, max_beats[i] * max_sixteenth, time, time * offbeat_decay.at(i), 1.5);
		// Squash sustained notes to make them shorter
		chain = ~squasher.value(chain, sixteenth, 0.7);
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
	// TODO: latch pan position on 16th notes?
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
		\amp, // downbeat regen
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
		[0.001, 4, \exp, 0], // blip level
		[0.001, 4, \exp, 0], // downbeat level
		[0.001, 4, \exp, 0], // kick level
		[0.001, 4, \exp, 0], // snare level
		[0.001, 4, \exp, 0], // tom level
		[0.001, 4, \exp, 0], // hihat level
]).gui;
)
