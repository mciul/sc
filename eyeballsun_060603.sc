// unfunky percussion-like pops
// Mike Ciul 2006-06-01
// Requires the FeedbackMatrix class
// look for it at http://www.eyeballsun.org/sc

(
// boot the server
// we will be scoping the output, so use internal
s=Server.internal;
s.boot;
)

(
// set up synthdefs

SynthDef("fbLFODelay", { arg in, out, time, freq, depth, maxtime = 0.5;
	// later effects should ReplaceOut on this bus
	// time is center delay time - must be greater than block size
	// freq is LFO freq - should be within control range
	// LFO depth should be in range 0-1

	var blockSize, adjustedDelay, lfoAmp;
	blockSize = ControlRate.ir.reciprocal;
	adjustedDelay = time - blockSize;
	lfoAmp = adjustedDelay * depth;
	         
         OffsetOut.ar(out, DelayC.ar(InFeedback.ar(in, 1), maxtime, SinOsc.kr(freq, 0, lfoAmp, adjustedDelay)));
} ).send(s);

SynthDef("fbRingMod", { arg out, freq, wet = 1;
	var effect = wet.sqrt, direct = (1 - wet).sqrt;
	ReplaceOut.ar( out, In.ar( out ) * SinOsc.ar( freq, 0, effect, direct ) );
} ).send(s);

SynthDef("fbPitchShift", { arg out, windowSize = 0.01, pitchRatio = 1, 
					pitchDispersion = 0, timeDispersion = 0.0001, wet = 1;
	var in = In.ar( out ), effect = wet.sqrt, direct = (1 - wet).sqrt;
	ReplaceOut.ar( out, 
		PitchShift.ar( in, windowSize, pitchRatio, pitchDispersion, timeDispersion, effect, direct * in) );
} ).send(s);

SynthDef("fbSoftclip", { arg out, gain = 1;
	ReplaceOut.ar( out, LeakDC.ar((In.ar(out) * gain ).softclip ) );
}).send(s);

SynthDef("fbDoubleCompander", { arg out, threshold1 = 0.1, threshold2 = 0.5,
		slope0 = 1, slope1 = 1, slope2 = 1, clampTime = 0.1, relaxTime = 0.1, gain = 1;

	var in = LeakDC.ar(In.ar(out) ), compander1;
	compander1 = Compander.ar( in, in, threshold1, slope0, slope1, clampTime, relaxTime );

	ReplaceOut.ar( out, Compander.ar( compander1, in, threshold2, 1, slope2 - slope1, 
				clampTime, relaxTime, gain ).distort );
}).send(s);

SynthDef("fbPercGate", { arg out, threshold, delayTime, attackTime, releaseTime, floor = 0, gain = 1;
	var in = LeakDC.ar(In.ar(out) ), gate, ampAttack = 0.001, ampDecay = 0.01,
		closedLevel = floor * gain, openLevel = ( 1 - floor ) * gain, env;
	gate = threshold - Amplitude.kr( in, ampAttack, ampDecay );
	env = Env.dadsr( delayTime, attackTime, 0, 1, releaseTime, 1 );
	ReplaceOut.ar( out, ( in * ( closedLevel + EnvGen.kr( env, gate, openLevel ) ) ).distort );
}).send(s);

SynthDef("hiss", { arg out, mul = -80.dbamp;
	Out.ar( out, PinkNoise.ar(mul) );
}).send(s);

SynthDef("hiss_swell", { arg out, duration=1, level = -60.dbamp, curve=1;
	Out.ar( out, PinkNoise.ar(EnvGen.kr(Env.sine( duration, level ), doneAction: 2) ) );
}).send(s);

)

(
// start the noise!

m.free;
m=FeedbackMatrix( s );
		
m.setFBChannels( 
	// delay synth layer
	[ \fbLFODelay ],
	[
	 	\time,  [ 2/1420, 3/1420, 4/1420, 10/1420 ],
	 	\freq,  [ 1/12.97, 1/25, 1/3.49, 1/6.73 ],
	 	\depth, [ 0.03, 0.03, 0.01, 0.01 ],
	 	\maxtime, 16/355 
 	],
 	// effect synth layer
 	[ \fbRingMod, \fbRingMod, \fbRingMod, \fbPitchShift ],
 	[
 		\freq, [ (1420/2) - (1420/16), 35.5, 1420/20, nil ],
 		\pitchRatio, [ nil, nil, 1/4, 3 ],
 		\wet, [ 0.3, 0.3, 0.7, 0.2 ]
 	],
 	// limiter synth layer
 	[ \fbPercGate ],
 	[	
		\threshold, [ 0.1, 0.1, 0.3, 0.4 ],
		\floor, [0.2, 0.2, 0.2, 0.1],
		\delayTime, [ 1/16, 3/32, 3/4, 2 ],
		\attackTime, [ 0.005, 0.005, 0.005, 4],
		\releaseTime, [0.01, 0.01, 0.01, 1.5],
		\gain, [ 4, 4, 8, 2 ] * 1
	]
);

m.setFBMix( [ \pan, [ -1, 1, 0, -1 ] ] );
m.setFBMix( [ \level, [ 0.2, 0.5, 1, 0.2 ] ] );

// scope the feedback channels. Useful for debugging (like finding out I needed LeakDC in the feedback loop!)
~scope = s.scope( m.fbChannels, m.outputBus[0].index );

// background hiss. The first one comes once then goes away. The second one is at a very low level.
m.setSourceChannels( ["hiss_swell", "hiss"], [\level, [1, nil], \duration, [7, nil], \mul, [ nil, -60.dbamp]] );

// create all effects sends - this generates the feedback matrix

m.setFBSends( [
	[ 1,		0,		0.2,		0],
	[ 0.4,		1,		0.2,		0.0],
	[ 0,		1,		0.5,		0.1 ],
	[ 1,		0.0,		0.0,		1.0 ]
] );

m.setSourceSends([
	[ 0, 0, 0, 1] * 0.00000001, // wow!
	[ 1, 1, 1, 1 ] * 0
]);

)

(
// make it stop

m.setSourceSends([
	[ 0, 0, 0, 0],
	[ 0, 0, 0, 0]
]);

m.setFBSends( [
	[ 0.1,		0,		0.0,		0],
	[ 0.4,		0.1,		0.0,		0.0],
	[ 0,		1,		0.0,		0.1 ],
	[ 1,		0.0,		0.0,		1 ]
] );
)
