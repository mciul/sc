(
/*********************************** DATA ***********************************/
~highestNote = 76 - 4; // 76 = highest possible note w/ default control rate
~tonic = ~highestNote-36;
f = ~tonic.midicps; // "fundamental" frequency - somewhat arbitrary
~delayKeys = [\eighth, \sixth, \fifth, \quarter, \third, \half];
~delayPairs = [~delayKeys, ~delayKeys].allTuples;
~delayTimes = Dictionary.newFrom(
	[~delayKeys, (f * [8,6,5,4,3,2]).reciprocal].flop.flatten;
);

~feedbackPaths = Array.fill(128, { [] });
~feedbackPaths[~tonic+36] = [\eighth]; // 8f = tonic + 36.0 semitone
~feedbackPaths[~tonic+31] = [\sixth]; // 6f = tonic + 31.019550008653873 semitone
~feedbackPaths[~tonic+28] = [\fifth]; // 5f = tonic + 27.863137138648348 semitone
~feedbackPaths[~tonic+24] = [\quarter]; // 4f = tonic + 24.0 semitone
~feedbackPaths[~tonic+21] = [\sixth, \eighth]; // 24/7 f = tonic + 21.331290943962625 semitone
~feedbackPaths[~tonic+20] = [\fifth, \eighth]; // 40/13f = tonic + 19.457860520955244 semitone
~feedbackPaths[~tonic+19] = [\third]; // 3f = tonic + 19.019550008653876 semitone
~feedbackPaths[~tonic+18] = [\fifth, \sixth]; // 30/11f = tonic + 17.36950772365466 semitone
~feedbackPaths[~tonic+17] = [\quarter, \eighth]; // 8/3 f = tonic + 16.980449991346124 semitone
~feedbackPaths[~tonic+15] = [\quarter, \sixth]; // 12/5 f = tonic + 15.156412870005525 semitone
~feedbackPaths[~tonic+14] = [\quarter, \fifth]; // 20/9 f = tonic + 13.8240371213406 semitone
~feedbackPaths[~tonic+13] = [\third, \eighth]; // 24/11f = tonic + 13.50637058500631 semitone
//~feedbackPaths[~tonic+13] = [\fifth, \sixth, \eighth]; // 120/59f = tonic + 12.29097055496013 semitone
~feedbackPaths[~tonic+12] = [\half]; // 2f = tonic + 12.0 semitone
~feedbackPaths[~tonic+11] = [\third, \fifth]; // 15/8 f = tonic + 10.88268714730222 semitone
//~feedbackPaths[~tonic+10] = [\quarter, \sixth, \eighth]; // 24/13f = tonic + 10.614273390960768 semitone
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

~controlSettings = Dictionary.newFrom([
	\bend, 0,
	\mod, 0,
	\overdrive, 1,
	\master, 0.2
]);

~mapToDict = {
	arg keys, value_func;
	Dictionary.newFrom(
		keys.collect({ |key, i|
			[ key, value_func.value(key, i) ]
		}).as(Array).flatten
	);
};

~feedbackLinks = ~feedbackPaths.collect({ |origins, notenum|
	var outs;
	outs = origins.rotate(-1);
	origins.collect({ |in, i|
		[in, outs[i]]
	});
});

~linkUsers = ~mapToDict.value(~delayPairs, { |link|
	(0..~feedbackLinks.size-1).select({ |i|
		~feedbackLinks[i].any({ |other| other == link });
	})
});

~currentVelocities = Array.fill(~feedbackLinks.size, 0);

/********************************** SYNTHS **********************************/

~loadSynthDefs = {
	//synthdefs

	SynthDef(\resonator, {
		arg in=0, out=~out, feedback_out=0, maxdelaytime=0.2, latency=0,
		delaytime=440.reciprocal, depth=0, decaytime=10, pathcount=1;
		var sig, amp, vibrato;
		amp = (-60 * delaytime/(decaytime)).dbamp;
		latency = (
			// default latency is 1/ControlRate
			latency.max(ControlRate.ir.reciprocal)
			// account for filter effects
			+ (1.5 / SampleRate.ir)
		);
		vibrato = SinOsc.kr(
			freq: LFNoise1.kr(1).range(6,9),
			mul: LFNoise1.kr(1).range(0.5, 1);
		) * depth;
		delaytime = delaytime / vibrato.midiratio;
		sig = In.ar(in);
		sig = LPF.ar(sig, 10000);
		sig = sig * Slew.kr(pathcount.reciprocal, 2.8, 10*pathcount);
		sig = DelayL.ar(
			sig, maxdelaytime, (delaytime - latency), amp
		).fold(-1,1);
		sig = LeakDC.ar(sig, coef:0.9995);
		Out.ar(feedback_out, sig);
		Out.ar(out, sig);
	}).add;

	SynthDef(\feedback, {
		arg in=0, out=0, amp=0.3, gate=0, depth=0, max_overdrive=1;
		var sig, env, overshoot, tremelo, filterEnv;
		// create pluck with a big attack when overdrive is low
		// but reduce the attack when velocity is low
		overshoot= max_overdrive.linexp(1,2.5,amp.linexp(0,1,50,1000),4);
		// open up more slowly for lower velocity
		filterEnv = EnvGen.ar(
			Env.asr(amp.linlin(0,1,12/f,0.125/f),1,0.3),
			gate
		);
		tremelo = SinOsc.kr(
			freq: LFNoise1.kr(1).range(6,9),
			mul: LFNoise1.kr(1).range(-1, -0.5);
		) * depth;
		// rise to overshoot level, then sustain at unity
		env = EnvGen.ar(
			Env.adsr(
				attackTime: 0.2/f,
				decayTime: 0.2/f,
				sustainLevel:overshoot.reciprocal,
				releaseTime:0.3
			),
			gate,
			levelScale: overshoot,
			doneAction:0
		);
		// simulate energy dissipating over parallel connections
		// clamp down quickly, release more slowly
		sig = (
			LPF.ar(InFeedback.ar(in), filterEnv.linlin(0,1,20,10000))
			* env
			* amp.linlin(1/64, 1, 1, max_overdrive)
			* tremelo.dbamp
		);
		Out.ar(out, sig);
	}).add;

	SynthDef(\noiseFloor, {
		arg out=0, amp=0.001;
		Out.ar(out, HPF.ar(BrownNoise.ar(amp!~delayKeys.size), 40));
	}).add;

	SynthDef(\mixOut, {
		arg in, out, amp=0.2;
		var sig;
		sig = In.ar(in, ~delayKeys.size);
		sig = Splay.ar(LeakDC.ar(sig));
		sig = Compander.ar(sig, sig, thresh: 0.2, slopeAbove:0.2, mul:amp);
		Out.ar(out, sig);
	}).add;
};

/******************************* SERVER SETUP *******************************/

~out = 0;
~makeBusses = {
	~bus = Dictionary.newFrom([
		\feedback, Bus.audio(s, ~delayKeys.size),
		\res, Bus.audio(s,~delayKeys.size),
		\mixOut, Bus.audio(s, ~delayKeys.size)
	]);
	~busAt = ~mapToDict.value(~bus.keys, { |busKey|
		~mapToDict.value(~delayKeys, { |delayKey, i|
			~bus[busKey].index + i
		});
	});
};


~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

/****************************** NODE TREE SETUP *****************************/

~delayTimeFor = { |key|
	~delayTimes[key] / ~controlSettings[\bend].midiratio
};

~makeNodes = {
	s.bind({
		~group = Dictionary.new;
		~group.add(\res -> Group.new);
		~group.add(\feedback -> Group.before(~group[\res]));
		~group.add(\mixOut -> Group.after(~group[\res]));
		~gateSynths = ~mapToDict.value(~delayPairs, { |in_out|
			var in, out;
			# in, out = in_out;
			Synth.new(
				\feedback, [
					\in, ~busAt[\feedback][in],
					\out, ~busAt[\res][out],
					\gate, 0,
					\depth, (~controlSettings[\mod]-0.75).max(0) * 24,
					\max_overdrive, ~controlSettings[\overdrive]
				],
				~group[\feedback]
			);
		});
		~delaySynths = ~mapToDict.value(~delayKeys, { |key|
			"delaySynth[".post;
			key.post;
			"] reading from ".post;
			~busAt[\res][key].post;
			" writing to ".post;
			~busAt[\feedback][key].postln;
			Synth.new(\resonator,
				[
					\in, ~busAt[\res][key],
					\feedback_out, ~busAt[\feedback][key],
					\out, ~busAt[\mixOut][key],
					\delaytime, ~delayTimeFor.value(key),
					\decaytime, 30 * ~delayTimes[key] * f,
					\depth, ~controlSettings[\mod] * 1.5
				],
				~group[\res]
			);
		});
		~outSynth = Synth.new(
			\mixOut, [\out, ~out, \in, ~bus[\mixOut].index], ~group[\mixOut]
		);
		~noiseSynth = Synth.head(
			~group[\res], \noiseFloor, [\out, ~bus[\feedback].index]
		);
	});
};


/******************************* MIDI CONTROLS ******************************/

~updateLinks = {
	arg midi, velocity=0;
	"note ".post;
	midi.post;
	", velocity ".post;
	velocity.post;
	" - ".post;
	~feedbackPaths[midi].postln;
	~currentVelocities[midi] = velocity;
	~feedbackLinks[midi].do({ arg link; ~updateLink.value(link)});
};

~linkVelocities = {
	arg in_out;
	~linkUsers[in_out].collect(~currentVelocities[_]);
};

~pathUsed = {
	arg path;
	~linkVelocities.value(path).any(_ > 0);
};

~updateLink = {
	arg in_out;
	var in, out, velocity;
	var amp, pathcount;
	# in, out = in_out;
	velocity = ~linkVelocities.value(in_out).maxItem;
	pathcount = (
		~delayKeys
		.collect([in, _])
		.count(~pathUsed.value(_))
		.max(1)
	);
	amp = (velocity.linlin(0,127,0,1));
	"link ".post;
	in_out.post;
	" velocity=".post;
	velocity.post;
	" pathcount=".post;
	pathcount.postln;
	~delaySynths[in].set(\pathcount, pathcount);
	~gateSynths[in_out].set(\amp, amp, \gate, velocity.min(1));
};

~controls = Dictionary.newFrom([
	\bend, { |val|
		~delayKeys.do({ |delayKey|
			~delaySynths[delayKey].set(
				\delaytime, ~delayTimeFor.value(delayKey)
			);
		})
	},
	\mod, { |val|
		~group[\res].set(\depth, val * 1.5);
		~group[\feedback].set(\depth, (val-0.75).max(0) * 24);
	},
	\overdrive, { |val|
		~group[\feedback].set(\max_overdrive, val);
	},
	\master, { |val|
		~group[\mixOut].set(\amp, val);
	}
]);

~setControl = { |key, val|
	~controlSettings[key] = val;
	~controls[key].value(val);
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
		~setControl.value(\bend, val.linlin(0,16383, -2, 2));
	});

	MIDIdef.cc(\modWheel, {
		arg val, num, chan, src;
		if (
			num == 1,
			{ ~setControl.value(\mod, val.linlin(0,127,0,1)) }
		);
	});
};

/******************************* GUI CONTROLS *******************************/

~makeControl = {
	arg view, label, spec, width=60, slider_height=400, box_height=30;
	var slider, numberBox, key;
	key = label.toLower.asSymbol;
	slider = Slider(view, width@slider_height);
	numberBox = NumberBox(view, width@box_height)
	.clipLo_(spec.clipLo)
	.clipHi_(spec.clipHi)
	.decimals_(4-log10(spec.range.abs.ceil.max(1)));
	StaticText(view, width@box_height)
	.string_(label)
	.align(\center);
	slider.action_({ |obj|
		numberBox.valueAction_(spec.map(obj.value));
	});
	numberBox.action_({ |obj|
		~setControl.value(key, obj.value);
		slider.value_(spec.unmap(obj.value));
	});
	numberBox.valueAction_(spec.default);
};

~makeControlWindow = {
	arg label_specs, control_width=60, control_height=600, box_height=30,
	border=30, margin=15;
	var win, window_width, label_spec_pairs;
	label_spec_pairs = label_specs.clump(2);
	window_width = (
		(label_spec_pairs.size * control_width)
		+ (margin * (label_spec_pairs.size - 1))
		+ (border * 2)
	);
	win = Window.new("Controls", Rect(
		Window.screenBounds.width - window_width - 200,
		100,
		window_width,
		control_height + (border*2);
	))
	.front;
	win.view.decorator_(
		FlowLayout(win.bounds, border@border, margin@margin)
	);
	label_spec_pairs.do { |label_spec|
		var label, spec, view, slider_height;
		slider_height = control_height - (2 * (box_height + margin));
		#label, spec = label_spec;
		view = View.new(win, control_width@control_height);
		view.decorator_(FlowLayout(view.bounds, 0@0, 0@margin));
		~makeControl.value(
			view,
			label,
			spec,
			control_width,
			slider_height,
			box_height
		);
	};
	win;
};

~makeControls = { |server|
	~mapKeyboard.value();
	Window.closeAll;
	w = ~makeControlWindow.value([
		"Master", ControlSpec(0.005, 1, \exp, default:0.2),
		"Overdrive", ControlSpec(1, 1.8, \exp)
	]);
	server.scope(6,4, bufsize:s.sampleRate/f);
};


/********************************** RUNTIME *********************************/

~startServer = {
	//ServerBoot.add(~makeBusses);
	ServerQuit.add(~cleanup);
	s.waitForBoot({
		"waitForBoot".postln;
		~makeBusses.value();
		s.sync;

		~loadSynthDefs.value();
		// remaining functions
		ServerTree.add(~makeNodes);
		"groups: ".post;
		~group.postln;
		ServerTree.add(~makeControls);
		s.freeAll;
		s.sync;


		"done".postln;
	});
};

if(
	s.serverBooting || s.hasBooted,
	{s.quit(onComplete:~startServer)},
	~startServer
);
)

s.plotTree
s.quit

~setControl.value(\overdrive, 1.15);

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
