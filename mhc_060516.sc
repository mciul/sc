// Feedback matrix
//
// A network of effects processors feeding back to each other.
// Thanks to David Lee Myers for his feedback music (and to Charles Cohen for telling me about it)
//
// - Mike Ciul 2006
// No copyright unless this comes with a GPL or Creative Commons license.

// To hear the noise, execute the first three blocks in parentheses.
// The stuff after that is for experimentation while the sound is running.
// One day there will be a GUI or some connections for controllers.

(
// boot the server
// we will be scoping the output, so use internal
s=Server.internal;
s.boot;
)

(
// set up groups and synthdefs

~feedback = Group.new(s);
	~fbDelay = Group.head(~feedback);
	~fbFX = Group.tail(~feedback);
	~fbLimit = Group.tail(~feedback);
~sources = Group.after(~feedback);
~effects = Group.after(~sources);

~fbChannels = 4;		// number of channels for feedback
~sourceChannels = 1;	// number of input channels

~fbInputs = ( { Bus.audio(s,1) } ).dup( ~fbChannels );
~fbOutputs = ( { Bus.audio(s,1) } ).dup( ~fbChannels );
~sourceOutputs = ( { Bus.audio(s,1) } ).dup( ~sourceChannels );
~allOutputs = ~sourceOutputs ++ ~fbOutputs;

SynthDef("fbLFODelay", { arg in, out, time, freq, depth, maxtime = 0.5;
	// later effects should ReplaceOut on this bus
	// time is center delay time - must be greater than block size
	// freq is LFO freq - should be within control range
	// LFO depth should be in range 0-1
	// maxtime should be time * 2 + blocksize if depth=1.

	var blockSize, adjustedDelay, lfoAmp;
	blockSize = ControlRate.ir.reciprocal;
	adjustedDelay = time - blockSize;
	lfoAmp = adjustedDelay * depth;
	         
         OffsetOut.ar(out, DelayC.ar(InFeedback.ar(in, 1), maxtime, SinOsc.kr(freq, 0, lfoAmp, adjustedDelay)));
} ).send(s);

SynthDef("fbRingMod", { arg out, freq, direct = 0;
	ReplaceOut.ar( out, In.ar( out ) * SinOsc.ar( freq, 0, 1, direct ) );
} ).send(s);

SynthDef("fbPitchShift", { arg out, windowSize = 0.01, pitchRatio = 1, 
					pitchDispersion = 0, timeDispersion = 0.0001, direct = 0;
	var in = In.ar( out );
	ReplaceOut.ar( out, 
		PitchShift.ar( in, windowSize, pitchRatio, pitchDispersion, timeDispersion, 1, direct * in) );
} ).send(s);

SynthDef("fbSoftclip", { arg out, gain = 1;
	ReplaceOut.ar( out, LeakDC.ar((In.ar(out) * gain ).softclip ) );
}).send(s);

SynthDef("effectSend", { arg in, out, level; 
	Out.ar( out, In.ar(in) * level );
}).send(s);

SynthDef("mainOut", { arg in, level = 0.5, pan = 0;
	Out.ar( 0, Pan2.ar( In.ar(in), pan, level ) );
}).send(s);

SynthDef("hiss", { arg out, mul = -80.dbamp;
	Out.ar( out, PinkNoise.ar(mul) );
}).send(s);

)

(
// start the noise!

// The default setting takes about 20 seconds to get going.

// background hiss. Useful for getting things started. You can turn it off later.
a=Synth("hiss", [\out, ~sourceOutputs[0].index, \mul, 0.1], ~sources);

// The first synth in the feedback chain must be a delay, because InFeedback introduces a delay anyway.
// Create an array containing one synth for each channel.
~fbDelaySynth = [
	\in, ~fbInputs.collect( _.index ),
	\out, ~fbOutputs.collect( _.index ),
 	\time,  [ 1/105, 1/193, 1, 144/89 ],
 	\freq,  [ 1/12.97, 1/25, 1/3.49, 1/6.73 ],
 	\depth, [ 0.0005,0.001,0.01,0.9 ],
 	\maxtime, 2 
].flop.collect( { arg settings; Synth("fbLFODelay", settings, ~fbDelay); } );

~fbFXSynth = [ nil, nil, 
			Synth("fbRingMod", [ \out, ~fbOutputs[2].index, \freq, 355 ], ~fbFX),
			Synth("fbPitchShift", [ \out, ~fbOutputs[3].index, \pitchRatio, 17/13 ], ~fbFX)];
 
// The last synth in the chain should limit the output somehow.
// Again uses an array of channels
~fbLimitSynth = [ 
	\out, ~fbOutputs.collect( _.index ),
	\gain, 1
].flop.collect( { arg settings; Synth("fbSoftclip", settings, ~fbLimit); } );

// create a stereo output mix
~sourceMix = [
	\in, ~sourceOutputs.collect( _.index ),
	\level, 0.001,
].flop.collect( { |settings| Synth("mainOut", settings, ~effects) } );

~fbMix = [
	\in, ~fbOutputs.collect( _.index ),
	\level, 0.7/~fbChannels.sqrt,
	\pan, [-1, 1, -1, 1 ]
].flop.collect( { |settings| Synth("mainOut", settings, ~effects) } );

// create all effects sends - this generates the feedback matrix
~sourceSend=~sourceOutputs.collect( { |in|
	~fbInputs.collect( { |out|
		Synth("effectSend", [\in, in.index, \out, out.index, \level, 0.001], ~effects);
	} )
} );

l = [
	[ 0.99,	0,		0,	1 ],
	[ 0.3,		0.99,		1,	0 ],
	[ 0,		0,		0,	1 ],
	[ 0,		0.3,		1,	0 ]
];
~fbSend=~fbOutputs.collect( { |in, i|
	~fbInputs.collect( { |out, j|
		Synth("effectSend", [\in, in.index, \out, out.index, \level, l[i].[j]], ~effects);
	} )
} );

// scope the feedback channels. Useful for debugging (like finding out I needed LeakDC in the feedback loop!)
~scope = s.scope( ~fbChannels, ~fbOutputs[0].index );

)

//experiment with settings

// set all LFO freqs
[ 1/12.97, 1/25, 1/3.49, 1/6.73 ].do( { arg freq, i; ~fbDelaySynth[i].set(\freq, freq); } );
[ 12.97, 25, 13, 1/1.69 ].do( { arg freq, i; ~fbDelaySynth[i].set(\freq, freq); } );

// set all LFO depths
[ 0.0005,0.001,0.9,0.9 ].do( { arg depth, i; ~fbDelaySynth[i].set(\depth, depth); } );
[ 0.01,0.01,0.3,0.9 ].do( { arg depth, i; ~fbDelaySynth[i].set(\depth, depth); } );

// set all delay times
[ 1/105, 1/193, 1, 144/89 ].do( { arg time, i; ~fbDelaySynth[i].set(\time, time); } );
[ 15/8, 1/4, 1, 3/16 ].do( { arg time, i; ~fbDelaySynth[i].set(\time, time); } );


~fbFXSynth[2].set(\freq, 355);
~fbFXSynth[3].set(\pitchRatio, 11/13);

// set send level for background hiss
0.0.dup(~fbChannels).do( { arg level, i; ~sourceSend[0].[i].set(\level, level); } );

//  set distortion gain for all feedback channels.
1.dup(~fbChannels).do( { arg gain, i; ~fbLimitSynth[i].set(\gain, gain); } );

// set feedback levels
(
// this setting is a little sparser
l =	[
	[ 0.97,		0,		0,	0.8 ],
	[ 1,		0.7,		0.8,	0 ],
	[ 0,		0,		0,	0.8 ],
	[ 0,		0.6,		0.8,	0 ];
];
)
(
// this is a copy of the initial setting; reducing the 0.99 levels can cause a slow fadeout
l =  [
	[ 0.99,	0,		0,	1 ],
	[ 0.3,	0.99,	1,	0 ],
	[ 0,		0,		0,	1 ],
	[ 0,		0.3,		1,	0 ]
]
)
(
l.collect( { |row, i| row.collect( { |level, j|
		~fbSend[i].[j].set( \level, level);
	} )
} );
)

// set mix levels
( ~fbChannels.sqrt.reciprocal * [ 1, 1, 1, 1] ).collect( { |level, i| ~fbMix[i].set(\level, level) } );
[ -1, 1, -1, 1 ].collect( { |pan, i| ~fbMix[i].set(\pan, pan) } );

// show me some fibonacci-like numbers. I like to use these for delay times and LFO frequencies.
// the actual fibonacci series comes out with last=1.dup(2)
(
var last=1.dup(3);
20.do( { |i| last.wrapPut(i, last.sum.postln); } );
)

(
// Clean up. For some reason it doesn't work if you try to restart later.
// I usually just use cmd-.

~fbSend.do( _.do( _.free) );
~sourceSend.do( _.do( _.free) );
~fbMix.do( _.free );
~sourceMix.do( _.free );
a.free;
~fbDelaySynth.do(_.free);
~fbFXSynth.do(_.free);
~fbLimitSynth.do(_.free);
)
~scope.free;
s.queryAllNodes;
