(
~highestNote = 76 - 4; // 76 is the highest note available with default control raite
~tonic = ~highestNote-36;
f = ~tonic.midicps; // "fundamental" frequency - somewhat arbitrary
~delayTimes = Dictionary.newFrom(
	[\eighth, 1/8, \sixth, 1/6, \fifth, 1/5, \quarter, 1/4, \third, 1/3, \half, 1/2] * f.reciprocal
);
~delayKeys = ~delayTimes.keys.asArray;

~feedbackPaths = Array.fill(128, { [] });
~feedbackPaths[~tonic+36] = [\eighth]; // 8f = tonic + 36.0 semitone
~feedbackPaths[~tonic+31] = [\sixth]; // 6f = tonic + 31.019550008653873 semitone
~feedbackPaths[~tonic+28] = [\fifth]; // 5f = tonic + 27.863137138648348 semitone
~feedbackPaths[~tonic+24] = [\quarter]; // 4f = tonic + 24.0 semitone
~feedbackPaths[~tonic+21] = [\sixth, \eighth]; // 24/7 f = tonic + 21.331290943962625 semitone
~feedbackPaths[~tonic+19] = [\third]; // 3f = tonic + 19.019550008653876 semitone
~feedbackPaths[~tonic+17] = [\quarter, \eighth]; // 8/3 f = tonic + 16.980449991346124 semitone
~feedbackPaths[~tonic+15] = [\quarter, \sixth]; // 12/5 f = tonic + 15.156412870005525 semitone
~feedbackPaths[~tonic+14] = [\quarter, \fifth]; // 20/9 f = tonic + 13.8240371213406 semitone
~feedbackPaths[~tonic+12] = [\half]; // 2f = tonic + 12.0 semitone
~feedbackPaths[~tonic+11] = [\third, \fifth]; // 15/8 f = tonic + 10.88268714730222 semitone
~feedbackPaths[~tonic+10] = [\quarter, \fifth, \eighth]; // 40/23 f = tonic + 9.580393665964195 semitone
~feedbackPaths[~tonic+9] = [\third, \quarter]; // 12/7 f = tonic + 9.331290943962623 semitone
~feedbackPaths[~tonic+8] = [\half, \eighth]; // 8/5 f = tonic + 8.136862861351654 semitone
~feedbackPaths[~tonic+7] = [\half, \sixth]; // 3/2 f = tonic + 7.019550008653875 semitone
~feedbackPaths[~tonic+6] = [\half, \fifth]; // 10/7 f = tonic + 6.174878073957099 semitone
~feedbackPaths[~tonic+5] = [\half, \quarter]; // 4/3 f = tonic + 4.980449991346124 semitone
~feedbackPaths[~tonic+4] = [\half, \sixth, \eighth]; // 24/19 f = tonic + 4.04441984733085 semitone
~feedbackPaths[~tonic+3] = [\half, \third]; // 6/5 f = tonic + 3.1564128700055254 semitone
~feedbackPaths[~tonic+2] = [\half, \quarter, \eighth]; // 8/7 f = tonic + 2.31174093530875 semitone
~feedbackPaths[~tonic+1] = [\half, \quarter, \fifth]; // 20/19 f = tonic + 0.8880069773253213 semitone
~feedbackPaths[~tonic+0] = [\half, \third, \sixth]; // f = tonic + 0.0 semitone
~feedbackPaths[~tonic-1] = [\half, \quarter, \sixth, \eighth]; // 24/25 f = tonic -0.7067242686428228 semitone
~feedbackPaths[~tonic-2] = [\half, \third, \sixth, \eighth]; // 8/9 f = tonic -2.0391000173077494 semitone
~feedbackPaths[~tonic-3] = [\half, \third, \fifth, \sixth]; // 5/6 f = tonic -3.1564128700055254 semitone
~feedbackPaths[~tonic-4] = [\half, \third, \quarter, \sixth]; // 4/5 f = tonic -3.8631371386483475 semitone
~feedbackPaths[~tonic-5] = [\half, \third, \fifth, \sixth, \eighth]; // 40/53 f = tonic -4.871908316110041 semitone
~feedbackPaths[~tonic-6] = [\half, \third, \quarter, \sixth, \eighth]; // 8/11 f = tonic -5.513179423647567 semitone
~feedbackPaths[~tonic-7] = [\half, \third, \quarter, \fifth, \sixth]; // 20/29 f = tonic -6.432634802882516 semitone
~feedbackPaths[~tonic-8] = [\half, \third, \quarter, \fifth, \sixth, \eighth]; // 40/63 f = tonic -7.8642219433506515 semitone

~feedbackLinks = ~feedbackPaths.collect({
	arg origins, notenum;
	var outs;
	outs = origins.rotate(-1);
	origins.collect({
		arg in, i;
		[in, outs[i]]
	});
});

~linkUsers = Dictionary.new();
~delayKeys.do({
	arg source;
	~delayKeys.do({
		arg dest;
		var link;
		link = [source, dest];
		~linkUsers.add(
			link -> (0..~feedbackLinks.size-1).select({
				arg i;
				~feedbackLinks[i].any({ |other| other == link });
			})
		);
	});
});

~currentVelocities = Array.fill(~feedbackLinks.size, 0);
~gateSynths = Dictionary.new();
~delayKeys.do({
	arg in;
	~gateSynths.add(in -> Dictionary.new());
});

~out = 0;
~makeBusses = {
	~bus = Dictionary.new;
	~bus.add(\feedback -> Bus.audio(s, ~delayKeys.size));
	~bus.add(\res -> Bus.audio(s,~delayKeys.size));
	~bus.add(\mixOut -> Bus.audio(s, ~delayKeys.size));
	~busAt = Dictionary.new();
	~bus.keys.do({
		arg busKey;
		~busAt.add(busKey -> Dictionary.new());
		~delayKeys.do({
			arg delayKey, i;
			~busAt[busKey].add(delayKey -> (~bus[busKey].index + i));
		});
	});
};

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

~loadSynthDefs = {
	//synthdefs
	SynthDef(\distortedResonator, {
		arg in=0, out=~out, feedback_out=0, maxdelaytime=0.2, latency=0, delaytime=440.reciprocal, gain=1, amp=1;
		var sig;
		latency = latency.max(ControlRate.ir.reciprocal); // I'd make 1/ControlRate the default if I could
		sig = In.ar(in).madd(gain).softclip;
		sig = LPF.ar(sig, 10000);
		sig = DelayL.ar(sig, maxdelaytime, (delaytime - latency), amp);
		sig = LeakDC.ar(sig);
		Out.ar(feedback_out, sig);
		Out.ar(out, sig);
	}).add;

	SynthDef(\clippedResonator, {
		arg in=0, out=~out, feedback_out=0, maxdelaytime=0.2, latency=0, delaytime=440.reciprocal, decaytime=10;
		var sig, amp;
		amp = (-60 * delaytime/decaytime).dbamp;
		latency = latency.max(ControlRate.ir.reciprocal); // I'd make 1/ControlRate the default if I could
		sig = In.ar(in);
		sig = LPF.ar(sig, 10000);
		sig = DelayL.ar(sig, maxdelaytime, (delaytime - latency), amp).clip;
		//sig = LeakDC.ar(sig);
		Out.ar(feedback_out, sig);
		Out.ar(out, sig);
	}).add;

	SynthDef(\feedbackGate, {
		arg in=0, out=0, amp=0.3, gate=0;
		var sig, env, sustain;
		sustain = 0.7;
		env = EnvGen.ar(
			Env.adsr(decayTime: 0.2, sustainLevel:sustain, releaseTime:0.3),
			gate,
			doneAction:2
		);
		sig = InFeedback.ar(in) * env * amp * 4/sustain;
		Out.ar(out, sig);
	}).add;

	SynthDef(\feedbackPluck, {
		arg in=0, out=0, amp=0.3, gate=0, pathcount=1;
		var pluck, sig, env, attenuate;
		pluck = BrownNoise.ar(EnvGen.ar(Env.triangle((0.25/f), amp)));
		env = EnvGen.ar(
			Env.asr(attackTime:0, releaseTime:0.3),
			gate,
			doneAction:2
		);
		// this doesn't help when the paths are not identical
		// but there is a shared node between them
		//
		// Using a LeakDC doesn't help either - it kills sustain completely
		attenuate = pathcount.reciprocal;
		sig = InFeedback.ar(in) * attenuate * env + pluck;
		Out.ar(out, sig);
	}).add;

	SynthDef(\noiseFloor, {
		arg out=0, amp=0.001;
		Out.ar(out, BrownNoise.ar(amp!~delayKeys.size));
	}).add;

	SynthDef(\mixOut, {
		arg in, out;
		var sig;
		sig = In.ar(in, ~delayKeys.size);
		sig = Splay.ar(LeakDC.ar(sig));
		sig = Limiter.ar(sig);
		Out.ar(out, sig);
	}).add;
};

~makeNodes = {
	s.bind({
		~group = Dictionary.new;
		~group.add(\res -> Group.new);
		~group.add(\feedback -> Group.before(~group[\res]));
		~group.add(\mixOut -> Group.after(~group[\res]));
		~delaySynths = ~delayKeys.collect({
			arg key;
			Synth.new(\clippedResonator,
				[
					\in, ~busAt[\res][key],
					\feedback_out, ~busAt[\feedback][key],
					\out, ~busAt[\mixOut][key],
					\delaytime, ~delayTimes[key];
				],
				~group[\res]
			);
		});
		~outSynth = Synth.new(\mixOut, [\out, ~out, \in, ~bus[\mixOut].index], ~group[\mixOut]);
		~noiseSynth = Synth.new(\noiseFloor, [\out, ~bus[\feedback].index], ~group[\feedback]);
	});
};

~updateLinks = {
	arg midi, velocity=0;
	"note ".post;
	midi.post;
	", velocity ".post;
	velocity.post;
	" - ".post;
	~feedbackPaths[midi].postln;
	~currentVelocities[midi] = velocity;
	~feedbackLinks[midi].do({ arg link; ~updateLink.value(link, (velocity > 0))});
};

~linkVelocities = {
	arg in_out;
	~linkUsers[in_out].select({
		arg midi;
		~currentVelocities[midi] > 0;
	});
};

~updateLink = {
	arg in_out, onset;
	var in, out, velocities;
	"updateLink(".post;
	in_out.post;
	", ".post;
	onset.post;
	")".postln;
	# in, out = in_out;
	velocities = ~linkVelocities.value(in_out);
	"velocities=".post;
	velocities.postln;
	if (velocities.size == 0,
		{
			~gateSynths[in][out].set(\gate, 0);
			~gateSynths[in][out] = nil;
		},
		{
			var amp, sharedpaths;
			sharedpaths = ~delayKeys.collect({
				arg other_in;
				[other_in, out];
			}).select({
				arg other_in_out;
				"link velocities for shared path ".post;
				other_in_out.postln;
				": ".post;
				~linkVelocities.value(other_in_out).postln;
				~linkVelocities.value(other_in_out).size > 0;
			});
			"shared paths=".post;
			sharedpaths.postln;
			amp = (velocities.maxItem.linlin(0,127,0,1));
			if (onset,
				{
					~gateSynths[in][out].set(\gate, 0);
					~gateSynths[in][out] = Synth.new(\feedbackPluck,
						[
							\in, ~busAt[\feedback][in],
							\out, ~busAt[\res][out],
							\amp, amp,
							\pathcount, sharedpaths.size,
							\gate, 1
						],
						~group[\feedback]
					);
				},
				{
					~gateSynths[in][out].set(\amp, amp);
				}
			);
			~gateSynths.do({ arg synths; synths[out].set(\pathcount, sharedpaths.size)});
		}
	);
};

~controlGates = {
	arg key, val;
	// TODO
};

~mapKeyboard = {
	MIDIIn.connectAll;

	MIDIdef.noteOn(\noteOn, {
		arg val, num, chan, src;
		~updateLinks.value(num, val);
	});

	MIDIdef.noteOff(\noteOff, {
		arg val, num, chan, src;
		~updateLinks.value(num, 0);
	});

	MIDIdef.bend(\bend, {
		arg val, chan, src;
		~bend = val.linlin(0,16383, -2, 2);
		~controlGates.value(\bend, ~bend);
	});

	MIDIdef.cc(\modWheel, {
		arg val, num, chan, src;
		if (
			num == 1,
			{
				~mod = val.linlin(0,127,0,1);
				~controlGates.value(\mod, ~mod);
			}
		);
	});
};
)
(
~ loadSynthDefs.value();
s.freeAll;
)
s.quit;
(
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);
s.waitForBoot({
	"waitForBoot".postln;
	s.sync;

	~loadSynthDefs.value();
	// remaining functions
	ServerTree.add(~makeNodes);
	ServerTree.add(~mapKeyboard);
	s.freeAll;

	s.sync;

	"done".postln;
});
)

/*
(44100/64).cpsmidi ~= 76.77

full version:
~feedbackPaths[~tonic+36] = [\eighth] // 8/1f = tonic + 36.0 semitone
~feedbackPaths[~tonic+31] = [\sixth] // 6/1f = tonic + 31.019550008653873 semitone
~feedbackPaths[~tonic+28] = [\fifth] // 5/1f = tonic + 27.863137138648348 semitone
~feedbackPaths[~tonic+24] = [\quarter] // 4/1f = tonic + 24.0 semitone
~feedbackPaths[~tonic+21] = [\sixth, \eighth] // 24/7f = tonic + 21.331290943962625 semitone
//~feedbackPaths[~tonic+19] = [\fifth, \eighth] // 40/13f = tonic + 19.457860520955244 semitone
~feedbackPaths[~tonic+19] = [\third] // 3/1f = tonic + 19.019550008653876 semitone
//~feedbackPaths[~tonic+17] = [\fifth, \sixth] // 30/11f = tonic + 17.36950772365466 semitone
~feedbackPaths[~tonic+17] = [\quarter, \eighth] // 8/3f = tonic + 16.980449991346124 semitone
~feedbackPaths[~tonic+15] = [\quarter, \sixth] // 12/5f = tonic + 15.156412870005525 semitone
~feedbackPaths[~tonic+14] = [\quarter, \fifth] // 20/9f = tonic + 13.8240371213406 semitone
//~feedbackPaths[~tonic+14] = [\third, \eighth] // 24/11f = tonic + 13.50637058500631 semitone
//~feedbackPaths[~tonic+12] = [\fifth, \sixth, \eighth] // 120/59f = tonic + 12.29097055496013 semitone
~feedbackPaths[~tonic+12] = [\half] // 2/1f = tonic + 12.0 semitone
//~feedbackPaths[~tonic+12] = [\third, \sixth] // 2/1f = tonic + 12.0 semitone
~feedbackPaths[~tonic+11] = [\third, \fifth] // 15/8f = tonic + 10.88268714730222 semitone
//~feedbackPaths[~tonic+11] = [\quarter, \sixth, \eighth] // 24/13f = tonic + 10.614273390960768 semitone
~feedbackPaths[~tonic+10] = [\quarter, \fifth, \eighth] // 40/23f = tonic + 9.580393665964195 semitone
~feedbackPaths[~tonic+9] = [\third, \quarter] // 12/7f = tonic + 9.331290943962623 semitone
//~feedbackPaths[~tonic+8] = [\quarter, \fifth, \sixth] // 60/37f = tonic + 8.369246759754825 semitone
~feedbackPaths[~tonic+8] = [\half, \eighth] // 8/5f = tonic + 8.136862861351654 semitone
//~feedbackPaths[~tonic+8] = [\third, \sixth, \eighth] // 8/5f = tonic + 8.136862861351654 semitone
//~feedbackPaths[~tonic+7] = [\third, \fifth, \eighth] // 120/79f = tonic + 7.237318169176989 semitone
~feedbackPaths[~tonic+7] = [\half, \sixth] // 3/2f = tonic + 7.019550008653875 semitone
//~feedbackPaths[~tonic+6] = [\third, \fifth, \sixth] // 10/7f = tonic + 6.174878073957099 semitone
~feedbackPaths[~tonic+6] = [\half, \fifth] // 10/7f = tonic + 6.174878073957099 semitone
//~feedbackPaths[~tonic+6] = [\third, \quarter, \eighth] // 24/17f = tonic + 5.969995913649799 semitone
//~feedbackPaths[~tonic+5] = [\quarter, \fifth, \sixth, \eighth] // 120/89f = tonic + 5.173885975705449 semitone
//~feedbackPaths[~tonic+5] = [\third, \quarter, \sixth] // 4/3f = tonic + 4.980449991346124 semitone
~feedbackPaths[~tonic+5] = [\half, \quarter] // 4/3f = tonic + 4.980449991346124 semitone
//~feedbackPaths[~tonic+4] = [\third, \quarter, \fifth] // 60/47f = tonic + 4.227620927170575 semitone
~feedbackPaths[~tonic+4] = [\half, \sixth, \eighth] // 24/19f = tonic + 4.04441984733085 semitone
//~feedbackPaths[~tonic+3] = [\half, \fifth, \eighth] // 40/33f = tonic + 3.3304077063469073 semitone
//~feedbackPaths[~tonic+3] = [\third, \fifth, \sixth, \eighth] // 40/33f = tonic + 3.3304077063469073 semitone
~feedbackPaths[~tonic+3] = [\half, \third] // 6/5f = tonic + 3.1564128700055254 semitone
//~feedbackPaths[~tonic+2] = [\half, \fifth, \sixth] // 15/13f = tonic + 2.4774105296091147 semitone
~feedbackPaths[~tonic+2] = [\half, \quarter, \eighth] // 8/7f = tonic + 2.31174093530875 semitone
//~feedbackPaths[~tonic+2] = [\third, \quarter, \sixth, \eighth] // 8/7f = tonic + 2.31174093530875 semitone
//~feedbackPaths[~tonic+2] = [\third, \quarter, \fifth, \eighth] // 120/109f = tonic + 1.6644752499791071 semitone
//~feedbackPaths[~tonic+2] = [\half, \quarter, \sixth] // 12/11f = tonic + 1.5063705850063096 semitone
//~feedbackPaths[~tonic+1] = [\third, \quarter, \fifth, \sixth] // 20/19f = tonic + 0.8880069773253213 semitone
~feedbackPaths[~tonic+1] = [\half, \quarter, \fifth] // 20/19f = tonic + 0.8880069773253213 semitone
//~feedbackPaths[~tonic+1] = [\half, \third, \eighth] // 24/23f = tonic + 0.7368065359697193 semitone
//~feedbackPaths[~tonic+0] = [\half, \fifth, \sixth, \eighth] // 120/119f = tonic + 0.14487398760689965 semitone
~feedbackPaths[~tonic+0] = [\half, \third, \sixth] // 1/1f = tonic + 0.0 semitone
//~feedbackPaths[~tonic-1] = [\half, \third, \fifth] // 30/31f = tonic + -0.5676685773402816 semitone
~feedbackPaths[~tonic-1] = [\half, \quarter, \sixth, \eighth] // 24/25f = tonic + -0.7067242686428228 semitone
//~feedbackPaths[~tonic-1] = [\third, \quarter, \fifth, \sixth, \eighth] // 40/43f = tonic + -1.2520399177768273 semitone
//~feedbackPaths[~tonic-1] = [\half, \quarter, \fifth, \eighth] // 40/43f = tonic + -1.2520399177768273 semitone
//~feedbackPaths[~tonic-1] = [\half, \third, \quarter] // 12/13f = tonic + -1.3857266090392308 semitone
//~feedbackPaths[~tonic-2] = [\half, \quarter, \fifth, \sixth] // 60/67f = tonic + -1.9103831381910463 semitone
~feedbackPaths[~tonic-2] = [\half, \third, \sixth, \eighth] // 8/9f = tonic + -2.0391000173077494 semitone
//~feedbackPaths[~tonic-3] = [\half, \third, \fifth, \eighth] // 120/139f = tonic + -2.544605725379868 semitone
~feedbackPaths[~tonic-3] = [\half, \third, \fifth, \sixth] // 5/6f = tonic + -3.1564128700055254 semitone
//~feedbackPaths[~tonic-3] = [\half, \third, \quarter, \eighth] // 24/29f = tonic + -3.2762219328769895 semitone
//~feedbackPaths[~tonic-4] = [\half, \quarter, \fifth, \sixth, \eighth] // 120/149f = tonic + -3.7473350982437177 semitone
~feedbackPaths[~tonic-4] = [\half, \third, \quarter, \sixth] // 4/5f = tonic + -3.8631371386483475 semitone
//~feedbackPaths[~tonic-4] = [\half, \third, \quarter, \fifth] // 60/77f = tonic + -4.318751341036596 semitone
~feedbackPaths[~tonic-5] = [\half, \third, \fifth, \sixth, \eighth] // 40/53f = tonic + -4.871908316110041 semitone
~feedbackPaths[~tonic-6] = [\half, \third, \quarter, \sixth, \eighth] // 8/11f = tonic + -5.513179423647567 semitone
//~feedbackPaths[~tonic-6] = [\half, \third, \quarter, \fifth, \eighth] // 120/169f = tonic + -5.9278660880839915 semitone
~feedbackPaths[~tonic-7] = [\half, \third, \quarter, \fifth, \sixth] // 20/29f = tonic + -6.432634802882516 semitone
~feedbackPaths[~tonic-8] = [\half, \third, \quarter, \fifth, \sixth, \eighth] // 40/63f = tonic + -7.8642219433506515 semitone
*/
(20/9).ratiomidi.mod(12)
