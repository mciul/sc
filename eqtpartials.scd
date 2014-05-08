(2..32).ratiomidi

 12, 19.019550008654, 24, 27.863137138648, 31.019550008654, 33.688259064691, 36, 38.039100017308, 39.863137138648, 41.513179423648, 43.019550008654, 44.405276617693, 45.688259064691, 46.882687147302, 48, 49.049554095004, 50.039100017308, 50.975130161323, 51.863137138648, 52.707809073345, 53.513179423648, 54.282743472684, 55.019550008654, 55.726274277297, 56.405276617693, 57.058650025962, 57.688259064691, 58.295771941531, 58.882687147302, 59.450355724642, 60 ]

[ 12, 19, 24, 28, 31, 36, 38, 40, 43, 47, 48, 49, 50, 51, 52, 55, 57, 59, 60 ] % 12

[ 0, 7, 0, 4, 7, 0, 2, 4, 7, 11, 0, 1, 2, 3, 4, 7, 9, 11, 0 ]
//   P5    M3       M2       M7     m2    m3       M6

(33..64).ratiomidi

[1] ++ [2]
s.quit
s.boot

(1/30) ** 0 / (1/30)
// try this if tweaks are needed
	var velocityRange = 1 + 1/partialCount;
	var velocityAdjustment = velocityRange - dampingEffect / velocityRange;

		((velocity * velocityAdjustment) ** partialCurvature)/velocityAdjustment;

(Instr(\eqtPrime, { arg freq=110, velocity=0.5, decayTime=20, dur=20, damping=1.7, releaseTime=0.1, amp=0.5, maxCentsError=25, partialCount=30;
	var maxPartials = 30;
	var partialsAsMidi = [1] ++ (partialCount.asInteger-1).collect({ |f| f.nthPrime.ratiomidi });
	var roundedMidi = partialsAsMidi.collect({ |m| m.round });
	var centsError = partialsAsMidi.collect({ |m| 100*abs(m.round - m) });
	var decayFactor = roundedMidi.collect({ |m, i|
		1/((i+1)**damping);
	});
	var dampingEffect = 1 / (2**damping);
	var maxVelocityCurve = 0.5;
	var minVelocityCurve = 2;
	var velocityCurveRange = minVelocityCurve - maxVelocityCurve;
	var velocityCurveFactor = velocityCurveRange/maxPartials;

	var ampFactor = roundedMidi.collect({ |m, i|
		var partialCurvature = i * velocityCurveFactor + maxVelocityCurve;
		var antiAliasing = (freq * m < SampleRate.ir/2).if(1, 0);
		//var antiError = (centsError[i] < maxCentsError).if(1, 0);
		var antiError = max(0, (maxCentsError - centsError[i])) / maxCentsError;
		antiAliasing * antiError * (velocity ** partialCurvature);
	}).postln;
	var normalizationFactor = 2 * sqrt(freq/SampleRate.ir) * (1-(dampingEffect*3/4))/ maxPartials;
	var stereoPluck = {WhiteNoise.ar(Decay.ar(Impulse.ar(0), 2/freq, normalizationFactor))}!2;
	var out = Klank.ar( `[roundedMidi.midiratio, ampFactor, decayFactor], stereoPluck, freq, 0, decayTime);
	var env = Env([decayTime, decayTime, 0], [dur, releaseTime]);
	out * EnvGen.kr(env, doneAction:2);
	},
	#[
		\freq,
		[0,60,\exp, 0],
		[1, 128, \lin, 1],
		[0,6,'exp',0],
		[-1,1,'lin',0]
	];
);

SynthDef(\eqtPrimeBass, { arg freq=110, velocity=0.5, amp=0.2, decayTime=20, dur=20, damping=1.7, releaseTime=0.1, maxCentsError=50;
	// strict max freq: 160 Hz
	// effective max freq: 550Hz
	Out.ar(0, Instr(\eqtPrime).ar(freq, velocity, decayTime, dur, damping, releaseTime, amp, maxCentsError, 30));
}).add;

SynthDef(\eqtPrimeTenor, {arg freq=220, velocity=0.5, amp=0.2, decayTime=20, dur=20, damping=1.7, releaseTime=0.1;
	// strict max freq: 280 Hz
	// effective max freq: 600Hz
	Out.ar(0, Instr(\eqtPrime).ar(freq, velocity, decayTime, dur, damping, releaseTime, amp, 25, 20));
}).add;

SynthDef(\eqtPrimeAlto, { arg freq=440, velocity=0.5, amp=0.2, decayTime=20, dur=20, damping=1.7, releaseTime=0.1;
	// max freq: 512 Hz
	// effective max freq: 800Hz
	Out.ar(0, Instr(\eqtPrime).ar(freq, velocity, decayTime, dur, damping, releaseTime, amp, 25, 13));
}).add;

SynthDef(\eqtPrimeSop, { arg freq=440, velocity=0.5, amp=0.2, decayTime=20, dur=20, damping=1.7, releaseTime=0.1;
	// max freq: 1158 Hz
	// effective max freq: 1250Hz
	Out.ar(0, Instr(\eqtPrime).ar(freq, velocity, decayTime, dur, damping, releaseTime, amp, 25, 7));
}).add;
)

(60+12).midicps
13.nthPrime
22000/43
1/(x**damping) = 0.3
3 = x**damping
3**(1/damping) = x

2 ** 0
2 ** 1
2 ** (-1000)
3**(1/0.5)
1/(1+(2**damping))
2-(4/(3+(2**0)))
2-(4/(3+(2**6)))
2 - (2**0)
2 - (2**6)

1/(30**damping) = x
1/(30**0.8)
1/(9**0.5)
15**(1/0.8)

300 ** (1/6)

//velocity adjustment
//at max damping:
//1 -> 1
//at 0 damping:
//1 -> max partial amp = 1/partialCount
//highest partial curvature = 2
//max velocity ** 2 = 1/partialCount
//0 damping adjustment = sqrt(1/partialCount)
//max damping adjustment = 1

1 / (2**6)
1 / (2**0)
()
s.scope
p = Patch(\eqtPrime, [55, 0.1, 20, 20, 1.7, 0.1, 30]).play;
n=p.asSynthDef.add.name;
p.send
p.name
(
p = Pbind(
	\degree, Pseq([1,2,3,4,5,6,7,6,5,4,3,[2, -10]], inf),
    \dur, 0.25,
        // \degree is EARLIER in the Pbind
    \legato, Pkey(\degree).linexp(-7, 7, 2.0, 0.05)
).play;
)
(
~go = true;
Pbind(
	\instrument, \eqtPrimeBass,
	\dur, Pseq([1, 0.5, 0.5, 1.5, 0.5, 1, 0.5, 0.5]/4, inf),
	\velocity, Prand([0.75, 0.5, 0.75, 1, 0.25] * 0.75, inf),
	\damping, Pseq([2, 1.5, 4, 3.5, 3, 0.8, 1.6], inf),
	\freq, Pwhile( {~go}, Pseq(12.midicps*[ 60, 72, 80, 90, 108, 80, 120 ]));
).play(quant:1);
)

~go = false;

(
p = Pbind(
	\freq, Pseq([50, 100, 75, 200], inf),
    // odd numbered scale degrees get a shorter rhythmic value
    \dur, Pif(Pkey(\freq) < 400, 0.25, 0.5)
).play
)

(
~go = true;
Pwhile({ ~go }, Pbind(
	\dur, 2,
	\velocity, Pseq([0.5, 0.6, 0.7, 0.6, 0.5, 0.4, 0.3], inf),
	\damping, Pseq([2, 1.5, 1, 1.8, 3, 4, 5, 1, 2, 2.5, 3], inf),
	\freq, Pseq(-24.midicps*60*[ [1], [2], [1,2], [3], [1,3], [5], [1,5], [3], [2,3], [5], [3,5]], 1),
	\instrument, \eqtPrimeBass
)).play(quant:1);
)

~go = false
p.next;
p

)



	\instrument, Pkey(\freq).collect({ |f|
		"f=".post;
		f.postln;
		case
		{f < 160} {\eqtPrimeBass}
		{f < 280} {\eqtPrimeTenor}
		{f < 512} {\eqtPrimeAlto}
		{true} {\eqtPrimeSop}
	}),

//superharmonic
//
//   12*13: sop
//   12*12: tenor/alto
//   12*11: bass
// (12*10).midicps/

// subharmonic
//
//     0: sop
//   -12: tenor/alto
//   -24: bass

Pseq([Pwalk([
		Pseq([1, 0.5, 0.5]),
		Pseq(0.5!4),
		Pseq([1.5, 0.5]),
		Pseq([2])
	],
		Prand([
			Pseq([3/8,1/8]),
			Pseq([1/8,1/4, 1/8]),
			Pseq([1/8, 1/8, 1/4]),
			Pseq([1/2])
		], 4)
(12*13).midicps/64
-12.midicps*120

\dur, Pseq([1, 0.5, 0.5, 1.5, 0.5] * 2, inf),

[Pwalk((12*11).midicps/[ 60, 72, 80, 90, 108 ], Prand([1, 0], inf))]
[ 60, 72, 80, 90, 108 ]
[ 64, 72, 75, 80, 90, 96, 100, 108, 120, 125 ]

(12*12).midicps/120
[9, 5, 6, 8, 12, 10, 24, 15, 16, 17, 18 ]
x=Synth.new(\eqtPrimeSynth);
x.free;

(
Instr(\simple, { arg freq=440;
	var out = SinOsc.ar([freq*0.999, freq*1.001], 0, Decay.ar(Impulse.ar(0), 1, 0.2));
	DetectSilence.ar(out);
	out;
});
)

Patch(\simple, [440]).play;
Patch(\simple, [110]).play;

[ 3, 4, 5 ].collect({ |i| [i*3, i*4, i*5] }).flatten.sort
[ 9, 12, 15, 16, 20, 25 ].collect({ |i| [i*3, i*4, i*5] }).flatten.sort
[ 27, 36, 45, 48, 60, 64, 75, 80, 100, 125 ]
[ 27, 36, 45, 60 ] * 2
54 * 2
[ 64, 72, 75, 80, 90, 96, 100, 108, 120, 125 ]
// 2  33 553   5 533   3   55  333   53  555
// F   G  G#   A   B   C   C#    D    E   E#
// F   G       A   B   C         D    E
//     G       A   B             D    E

//C = 60, 48, 36, 24, 12, 0, -12

-24.midicps * 64

//
333
33
533
53
5

33 -> 53

// center: 53
// modulate:
// up a 4th to 5
// up a m3 to 33
// up a 5th to 533
// down a M3 to 3

// or invert everything!

// 53 center:
[  60, 72, 80, 90, 108 ]
// 53  33   5 533  333
//  E   G   A   B    D

// minor (inverted) version:

1/[ 125, 120, 108, 100, 96, 90, 80, 75, 72, 64 ]
//  555   53  333   55   3 533   5 553  33   2
//   Cb    C    D   Eb   E   F   G  Ab   A   B

22000/127
150*127
(
SynthDef(\klankTest, {
	arg freq=440;
	var partials = [1, 127];
			var amps = partials.collect({ |p| (freq * p < 22000).if(1, 0);});
	var out = Klank.ar(`[partials, amps, 1], Impulse.ar(0), freq);
	Out.ar(0, [out, out]);
}).add;
)

(
	Pbind(\instrument, \eqtPrimeBass,
			\note, Pseq( [0, [-12, 0], [0, 4, 7], [-12, 0, 12, 24, 36]] ,2),
		\dur, 1,
		\maxCentsError, 50,
		\damping, 4,
		\velocity, 0.5).play
	)