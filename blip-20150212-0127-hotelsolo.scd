2**21

Server.killAll
s.options.memSize=(2**21).postln;
s.recSampleFormat = 'int16';
s.boot;
s.quit;
b.free;
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/backyard 20060801 1425.aiff" );
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/langelliott_american_crow.aiff" );
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/silence_chorus_nine.aiff");
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/milva_passiun_edit_1.aiff");
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/mono/silvermountain_theme_mono.aiff" );
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/hotel_solo.aiff" );
b = Buffer.read( s, "/Users/mciul/Google Drive/samples/harold_music.aiff" );

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
87.cpsmidi
87*3
87*4
75*4

88*4
(352+88)/2
87/16
8*25
16+25
16*6
41*6
(246+96)/2
171-96
171+75
(*75+171) - partials 16-41
32-25
70
320
(70+320)/2
195-70
(*125+195) - 70-320Hz, partials 7-32
(8+33)*3
(33-8)*3
(6+31)*3
(31-6)*3
(25/3*2+25)*3
88/25
(49+24)*3
195/6
75/5
125/5
15*6
25*6
//tweet
play{l=LFSaw;a=Decay.ar(Impulse.ar(1/8),0.2,l.ar(l.kr(2/25,0,125,195)));[8,16,3,10].do({|t|a=CombN.ar(a,6,t/8+[3,4],20,1,a)});a}//#sctweets

// shorter tweet - requires s.options.memSize=(2**15)
play{l=LFSaw;a=HPF.ar(l.ar(1/8),9,l.ar(l.kr(2/25,0,90,150)));5.collect{|d|a=CombN.ar(a,7,2**d/8+[4,5],36,1)}.sum}// #sctweets #supercollider


a=[1]++[[1,2]]
a=a++[[3,4]]
a.add [5,6]
[1,2,3,4].d
3.(2**d)
a=1
4.collect{|i|a=a+(2**i/8+[3,6])}.sum
2+5
176+88
14/25*2
9/8
32/75
5/6
16/2
25/32
(224.679/111.391).ratiomidi
(210.792/97.5526).ratiomidi
(210.792/88).ratiomidi
(97.5526/88).ratiomidi
(32/25).ratiomidi
8.midiratio
(25/16).ratiomidi
(253.143/189.595)*25
(189.595/126.09)*25
(239.008/175.362)*25
a=([112.527,225.244,161.809,98.3786,211.113,147.795,260.439,197.043,133.684,246.379,182.951,119.561,232.258,168.874,105.419,218.193,154.77,91.4048,204.127,140.757,253.418,190.041,126.642,239.299,175.97])
a.sort.do({|elem,i| (a.at(i)*25/176).round.postln})
(176/25).cpsmidi.mod(12)
440.cpsmidi.mod(12)
88*4-88
(
{
	var pitch=LFSaw.kr(2/25,0,88,176);
	// the pitch rises from 88Hz to 264Hz (an octave and a fifth) in 12.5 seconds
	var tone=LFSaw.ar(pitch);
	// generate a sawtooth wave following the pitch
	var env=Decay.ar(Impulse.ar(1/8),0.5);
	// 0.2 second percussive envelope that repeats once every 8 seconds
	var note=env*tone;
	/* the original tweet performs the same multplication in the
	 * mul: parameter of the Decay ugen
	 *
	 * this combination produces the 25 note cycle. The notes
	 * are harmonically related because the pitch rises in a linear
	 * fashion. If the pitch doesn't wrap around before the next note,
	 * it will be 32/25 * 88Hz higher. If it does wrap around, it
	 * will be 18/25 * 88Hz lower. The total set of all notes played
	 * consists of harmonic partials 13-37 of a fundamental frequency
	 * of 7.04 Hz.
	 */
	//[16,10,4,3].do({|t|a=CombN.ar(a,6,t/8+[3,4],20,1,a)});
	var delaytimes=[16,10,4,3];
	// delaytimes measured in 16th notes at 120bpm
	var out = note;
	// chain all the delays:
	delaytimes.do{|delay|
		var delayinseconds=delay/8;
		var stereodelay=[3,4];
		// left channel delays an additional 6 beats at 120bpm,
		// right channel delays an additional 8 beats
		out=CombN.ar(out,6,delayinseconds+stereodelay,24,1,out);
	};
	// uncomment this line to see what frequencies are being used:
	// Poll.ar(Impulse.ar(1/8),ZeroCrossing.ar(tone),"freq");
	out;
}.play
)

// This is the actual patch.
(
~blipGate = { |in, trig, gain|
	// Gate the input, and make sure the envelope decays no matter what
	// dynamic the input has at the moment.
	//
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
	var earTime=0.000625;
	DelayC.ar(Pan2.ar(in, pos, level), earTime, pos.madd(earTime/[2,-2],earTime/2));
};

~dynPan = { |in, depth, level|
	var maxfreq=100*2/60;
	var thresh=0.05;
	var freq=Amplitude.kr(in).min(thresh).madd(-1/thresh, add:1)*maxfreq;
	~headPan.value(in, SinOsc.kr(freq, 0, depth), level);
};

~looper = { |in, maxdelaytime, delaytime, regen, recovery=0.1, thresh=0.5|
	var node = FbNode(1, maxdelaytime);
	var recycle = node.delay(delaytime) * regen;
	// give a slight bias to new sounds by multiplying * 1.1
	var amps = Amplitude.ar([recycle,in],0.001,recovery,[thresh,1]);
	var out = SelectX.ar(amps[1]>amps[0], [recycle, in]);
	node.write(out);
	//recycle; // + in?
};

~squasher = { |in, squashtime, max_squash|
	var squash = Amplitude.ar(in, squashtime, squashtime/2, max_squash).min(1);
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

Instr(\blip, { arg bpm=113.917, gain=0.5, downbeat_regen=1, kick_regen=1, snare_regen=0.96, tom_regen=0.96, hihat_regen=1, kick_beat=13, snare_beat=3, tom_beat=11, hihat_beat=5, kick_freq=94.95, snare_freq=3438, tom_freq=1807, hihat_freq=8919, kick_squash=1, snare_squash=0.1, tom_squash=0.1, hihat_squash=0.1, blip_level=0.4, downbeat_level=0.3, kick_level=4, snare_level=4, tom_level=1, hihat_level=1.39;
	var sixteenth = 60 / 4 / bpm;
	var max_sixteenth = 60 / 4 / 100;
	// Trigger a gate to let the sample through on downbeats
	var downbeat = Impulse.ar( bpm / 60 / 4, 0 );
	var offbeat_regen = [kick_regen, snare_regen, tom_regen, hihat_regen];
	var offbeat_recovery = [3, 2, 2, 1] * sixteenth;
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
		chain = ~looper.value( chain, max_beats[i] * max_sixteenth, time, offbeat_regen.at(i), offbeat_recovery.at(i) ) * 1.5;
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
