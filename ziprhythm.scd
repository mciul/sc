

s = Server.local;
s.options.memSize=24576;
Server.default = s.boot;
(
// Define instruments.
// kick drum
Instr(\kick,
	{
		arg trigger, stickAttack=0.0001, stickDecay=0.001,startFreq = 50, endFreq = 20, decayTime = 1.2;
		var stick = Decay2.ar(trigger, stickAttack, stickDecay);
		var boomFreq = Decay.ar(stick, decayTime, (startFreq - endFreq), endFreq);
		var boom = Ringz.ar(stick, boomFreq, decayTime, 0.7);
		Pan2.ar(boom, 0);
	},
	#[
		[0.00001,0.001,\exp,0.00001],	// stickAttack
		[0.0001,0.01,\exp,0.0001],		// stickDecay,
		\freq,						// startFreq,
		\freq,						// endFreq,
		[0.1,3,\exp,0.01]				// decayTime
	]
);

// snare drum
Instr(\PMsnare,
	{
		arg trigger, stickDecay=0.01, topTension=0.032, bottomTension=0.022, topLoss=0.999, bottomLoss=0.999,
			snareRattle=92, snareDecay=0.28,
			snareFreq1=685, snareFreq2=2909, snareFreq3=4011,
			snareRQ1=0.105, snareRQ2=0.69, snareRQ3=0.47,
			snareMix1=0.026, snareMix2=0.033, snareMix3=0.091,
			wet=0.28,roomsize=0.01,damping=0.0005,
			topMix=0.31,bottomMix=0.034;
		var stick=Decay.ar(trigger, stickDecay);
		var top=MembraneCircle.ar(stick,topTension, topLoss);
		var bottom=MembraneCircle.ar(top, bottomTension,bottomLoss);
		var rattles=Ringz.ar(top-bottom, [0,2.4,4.8,7.2,9.6].midiratio * snareRattle, snareDecay);
		var snare=Mix.new(ToggleFF.ar(rattles) * rattles);
		snare = Mix.new(BPF.ar(snare, [snareFreq1, snareFreq2, snareFreq3], [snareRQ1, snareRQ2, snareRQ3], [snareMix1, snareMix2, snareMix3]));
		snare = FreeVerb.ar(snare, wet, roomsize, damping);
		[top * topMix + snare, bottom * bottomMix + snare];
	},
	#[
		\nil, 						// trigger
		[0.001,0.5,\exp,0.001],			// stickDecay
		[0.01,0.1,\exp,0.001],			// topTension
		[0.01,0.1,\exp,0.001],			// bottomTension
		[0.999,0.999999,\exp,0.000001],	// topLoss
		[0.999,0.999999,\exp,0.000001],	// bottomLoss
		\freq,			// snareRattle
		[0.1,3,\exp,0.01],						// snareDecay
		\freq,						// snareFreq1
		\freq,						// snareFreq2
		\freq,						// snareFreq3
		[0.01,1,\exp,0.0001],		// snareRQ1
		[0.01,1,\exp,0.0001],		// snareRQ2
		[0.01,1,\exp,0.0001],		// snareRQ3
		\amp,							// snareMix1
		\amp,						// snareMix2
		\amp,							// snareMix3
		\unipolar,					// wet
		\unipolar,					// room size
		\amp,						// damping
		\amp,						// topMix
		\amp,						// bottomMix
	]);
)
3.5/3*10000
[1,1.25,1.75,2,1,2,3,2,1].size
[0.5,1,2,2.5,3,2,1].size
(
		var fastFeedback=0.1;
		var slowFeedback=1;
		var bpm=130;
		var measure = 4 * 60 / bpm;
		var delayTime=[0.5,1,2,3] * measure;
		var maxDelayMeasures=3;
		var minDelayMeasures=0.5;
		var glitchBoost = (([0,0]).sum * 0.5).postln;
		var feedbackFactor = ((maxDelayMeasures - (delayTime.rotate / measure))/(maxDelayMeasures-minDelayMeasures)).postln;
		var delayFeedback = feedbackFactor * (glitchBoost+slowFeedback-fastFeedback) + fastFeedback;
		delayFeedback.postln
)

[-1, 0, 0.4, 1].minItem
inf.neg
-inf
[ -1, 2, 0.5, 0 ].arrayMin

(

		var rateSeqs = [
			[1,1,0.5,0.5] ++ [0.5,0.5,0.5,0.5] ++ [0.5,0.5,0.5,0.5] ++ [1,1,1,1] ++ [1,2,1,2] ++ [1,2,1,1] ++ [0,0,0,0] ++ [1,2,0.5,0.5] ++ [0.5,0.5,0.5,0.5] ++ [1,2,1,2] ++ [1/3,1/3,1/3,1/3] ++ [1,1,-1/3,1] ++ [1,2,1,2] ++ [2,2,2,2] ++ [2,2,2,2],

			(2!4) ++ (1!4) ++ (0!4) ++ (2!2) ++ (1!12) ++ (0.5!12) ++ (0.5!8) ++ (1!2) ++ (2!8),

			[1,0.5,0.5,0.5] ++ [1,1,0.5,1] ++ [0,0,0,2] ++ [2,2,2,2]
		];
		var minTimes = [3,4,4];

	rateSeqs.collect({ |seq, i|
		"rateSeq ".post;
		i.post;
		" size: ".post;
		seq.size.post;
		" sum=".post;
		seq.sum.postln;
		Instr.ar(\timeDseq, [seq, minTimes[i]]);
	});
)

// Zipping rhythm
(

	Instr(\timeDseq,
	{
		arg rateSeq, minTime=1, timeScale=1;

		var total = 0;

		"Input rate sequence: ".post;
		rateSeq.postln;
		rateSeq = rateSeq.collect({|d| total = total + 1 - d; total; });
		rateSeq = rateSeq - rateSeq.minItem + minTime;
		"Time sequence: ".post;
		rateSeq.postln;
		Dseq(rateSeq * timeScale, inf);
	});

	Instr(\upSlewDseq,
	{
		arg rateSeq;
		"Up Slew Sequence: ".post;
		Dseq(rateSeq.collect({|d| if (d>=1, 1, 1-d )}).postln, inf);
	});

	Instr(\ziprhythm,
	{
		arg kickGain=0.2, snareGain=0.05,fastFeedback=0.99,slowFeedback=1,forwardFeedback=1,reverseFeedback=0,glitchFactor0=0.5, glitchFactor1=0.5;
		var bpm = 160;
		var measure = 4 * 60 / bpm;
		// var beat = Impulse.ar(bpm/60);
		// var downbeat = PulseDivider.ar(beat, 4, [0,0]) + Impulse.ar(0);
		var beatSeq = [ 1, 0.2, 0.5, 0.5, 0.5, 0.2, 0.5, 0.2 ];
		var eighthTrig = Impulse.ar(bpm*2/60);
		var beat = PulseDivider.ar(eighthTrig, 2, [0,0]) + Impulse.ar(0);
		var beatTrig = (Demand.ar(eighthTrig, Dseq(beatSeq, inf)) * eighthTrig).postln;
		var rateSeqs = [
			[1,1,0.5,0.5] ++ [0.5,0.5,0.5,0.5] ++ [0.5,0.5,0.5,0.5] ++ [1,1,1,1] ++ [1,2,1,2] ++ [1,2,1,1] ++ [0,0,0,0] ++ [1,2,0.5,0.5] ++ [0.5,0.5,0.5,0.5] ++ [1,2,1,2] ++ [1/3,1/3,1/3,1/3] ++ [1,1,-1/3,1] ++ [1,2,1,2] ++ [2,2,2,2] ++ [2,2,2,2],

			(2!4) ++ (1!4) ++ (0!4) ++ (2!2) ++ (1!12) ++ (0.5!12) ++ (0.5!8) ++ (1!2) ++ (2!8),

			[1,0.5,0.5,0.5] ++ [1,1,0.5,1] ++ [0,0,0,2] ++ [2,2,2,2]
		];
		var minTimes = [2,3,3]; // one more beat will be added by the limiter

		var timeSeqs, slewSeqs, upSlew, delayTime;
		var delaySlope, upSlewMatch, glitchBoost;
		var feedbackFactor, delayFeedback;
		var recycle, delay, triggers, snare, kick;
		var feedback;
		var envFollower;

		"beatTrig=".post;
		beatTrig.postln;

		timeSeqs = rateSeqs.collect({ |rateSeq, i| Instr.ar(\timeDseq, [ rateSeq, minTimes[i], measure/4])});
		slewSeqs = rateSeqs.collect({ |rateSeq| Instr.ar(\upSlewDseq, [ rateSeq ] )});

		// the up-slew rate controls the playback rate when the delay time is increasing.
		// This is usually a downward pitch shift but it can do other interesting things.
		//   0.5=half rate
		//   7/8=1/8 rate
		//   1=stop playback. This creates some very interesting glitches
		//   1.5=half rate, backwards
		// We keep the down-slew rate at 1 (double rate) because other values just make a mess.
		// var slowDur=[inf,inf,2,3,inf,inf,inf,-2].stutter;
		upSlew=Demand.ar(beat,0,slewSeqs);
		delayTime=Slew.ar(Demand.ar(beat, 0, timeSeqs),upSlew,1);
		// increase feedback level for shorter delay times -
		// this causes a bias towards sounds that will be slowed down,
		// so very fast high-pitched sounds fade out instead of taking over
		delaySlope=Slope.ar(delayTime);
		// upSlewMatch=((1 - abs(upSlew)) > 0) * (delaySlope > 0);
		upSlewMatch=abs(1-delaySlope) < 0.01;
		glitchBoost = (upSlewMatch * glitchFactor0) + (upSlewMatch.rotate * glitchFactor1);
		feedbackFactor = delaySlope.sign + 1 / 2;
		delayFeedback = Lag.ar(feedbackFactor * (slowFeedback-fastFeedback) + fastFeedback + glitchBoost,0.001);
		recycle=LeakDC.ar(LPF.ar(LocalIn.ar(rateSeqs.size),10000));
		delay=DelayC.ar(recycle, 4*measure,delayTime - ControlRate.ir.reciprocal);

		envFollower=Amplitude.ar(delay);
		// snareTrigger = Impulse.ar(1/measure/2, 1/4) * LFClipNoise.ar(1/measure);
		// kickTrigger = Impulse.ar(1/measure) * LFClipNoise.ar(1/measure);
		triggers = max(0, envFollower + beatTrig - 1);
		"triggers=".post;
		triggers.postln;
		snare = Instr.ar(\PMsnare, [ triggers[0], 0.01, 0.032, 0.022, 0.999, 0.999, 126.8, 0.17, 685.0, 2909.0, 4011.0, 0.105, 0.69, 0.47, 0.0135, 0.0228, 0.0265, 0.313, 0.0, 0.760, 0.0, 0.0]) * snareGain;
		kick = Instr.ar(\kick, [ triggers[1], 7e-05, 0.0015, 29.88, 20.0, 0.43]) * kickGain;
		//(delaySlope).round(1/12).poll(downbeat);
		feedback = delayFeedback * delay;
		LocalOut.ar(Limiter.ar(
			[Mix(snare), Mix(kick), DC.ar(0)] + (forwardFeedback * feedback.rotate(1)) + (reverseFeedback * feedback.rotate(-1)),
			1,
			measure/4
		));
		Limiter.ar((snare + kick + Splay.ar(delay)) * 0.2, 1, measure/4);
	},
	#[
		\amp,					// kickGain
		\amp,					// snareGain
		\amp,					// fastFeedback
		\amp,					// slowFeedback
		\amp,					// forwardFeedback
		\amp,					// reverseFeedback
		\amp,					// glitchFactor0
		\amp						// glitchFactor1
	]
	).gui;
)

(
	t = (2!1) ++ (1!3) ++ (1!4) ++ (0.5!6);
	"array: ".post; t.postln;
	"size: ".post; t.size.postln;
	"sum: ".post; t.sum.postln;
	"change: ".post;
	u = 0;
	t.collect({|d| u = u + d - 1; (u.round(1/6) + 3)*6; }).postln;
)

// Tape-delay style:
(
	var bpm = 130;
	var measure = 4 * 60 / bpm;

	b.free;
	c.free;
	b = Buffer.alloc(s, 44100 * measure * 2, 1 );
	c = Buffer.alloc(s, 44100 * measure * 2, 1 );

	Instr( \tapeDelayZipRhythm,
	{
		arg kickGain=1, snareGain=0.35, feedback=0.999, reverse=0.1;
		var beat=Impulse.ar(4/measure);
		var downbeat=PulseDivider.ar(beat, 4);
		var snareTrigger = Impulse.ar(1/measure/2, 1/2);
		var kickTrigger = Impulse.ar(1/measure);
		var snare = Instr.ar(\PMsnare, [ snareTrigger, 0.01, 0.032, 0.022, 0.999, 0.999, 126.8, 0.17, 685.0, 2909.0, 4011.0, 0.105, 0.69, 0.47, 0.0135, 0.0228, 0.0265, 0.313, 0.0, 0.760, 0.0, 0.0]) * snareGain;
		var kick = Instr.ar(\kick, [ kickTrigger, 7e-05, 0.0015, 29.88, 20.0, 0.43]) * kickGain;
		var in = snare + kick;
		// var pitchSeq = ( [ 0, 0, 5, 0, 3, 2, 0 ] + 36 ).midicps;
		// var in = Ringz.ar( downbeat, Demand.ar(beat, 0, Dseq( pitchSeq, inf )), 0.5 );
		var bRateSeq= ([1,2,1,1] ++ [1,0.5,0.5,0.5] ++ [0.5,2,2,2] ++ [1/3,1,-1/3,1] ++ [1,1,1,1]);		var cRateSeq= (2!1) ++ (1!3) ++ (1!4) ++ (0.5!6);
		var rate = [bRateSeq, cRateSeq].collect({ |seq| Demand.ar(beat, 0, Dseq( seq/2, inf ) )} );
		//var rate=({2**(TIRand.ar(0,2,downbeat)-1) * LFNoise0.ar(1/measure,add:1-(reverse*2)).sign}!2).postln;

		var phase = [b,c].collect({ |buf, i| Phasor.ar(0, BufRateScale.kr(buf.bufnum) * rate[i], 0, BufFrames.kr(buf.bufnum))});

		var out = [b,c].collect( { |buf, i| LeakDC.ar(LPF.ar(BufRd.ar(1, buf.bufnum, phase[i], interpolation:4), 5000)) } );

		[b,c].collect( { |buf, i| BufWr.ar( in.sum + (feedback * out.rotate[i]), buf.bufnum, phase[i]) } );

		in + out;
	},
	#[
		\amp, // kickGain
		\amp, // snareGain
		\amp, // feedback
		\amp, // reverse
	]
	).gui;
 )
