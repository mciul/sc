/*
An idea for either vocoder bands
or additive harmonics which are only
multiples of 2, 3, or 5.

To cover a full scale, two sets are used,
a whole tone apart. It turns out if
we leave out multiples of 9 in both tones, there are no
close overlaps between bands.

The question remains - equal tempered whole tone?
9/8? 10/9? an average of the two?

Also, I'd like to listen to a synth with these partials -
compare with a synth having prime partials and
a sawtooth, both in individual notes and in chords
*/

s.quit;
Server.killAll
s.options.memSize=(2**21).postln;
s.options.numWireBufs=2048;
s.recSampleFormat = 'int16';
s.boot;
b.free;

(
~ionian_one=10;
~partials=(2..2500).select({ |x| (x.factors.last < 7) && (x % 9 > 0)});
~notes=~partials.collect({|x| x * (~ionian_one-[7,5]).midicps}).flatten.select({|f| (f>20.0) && (f<20000.0)}).sort;
)
~notes.cpsmidi.round
~notes[10].cpsmidi.round
(52-15)/12
~notes.last
~notes.size

61.collect((_+1).reciprocal).normalizeSum
(
SynthDef.new(\tonalSynth, {|out, freq=440, amp=0.1, dur=5, pan=0|
	var tone = Klang.ar(`[[1] ++ ~partials[0..30], 32.collect((_+1).reciprocal), nil], freq).madd(EnvGen.ar(Env.perc(releaseTime:dur), doneAction:2));
	OffsetOut.ar(out, Pan2.ar(tone, pan, amp));
}).send

SynthDef.new(\primeSynth, {|out, freq=440, amp=0.1, dur=5, pan=0|
	var tone = Klang.ar(`[[1] ++ 31.collect({|x| nthPrime(x)}), 32.collect((_+1).reciprocal), nil], freq).madd(EnvGen.ar(Env.perc(releaseTime:dur), doneAction:2));
	OffsetOut.ar(out, Pan2.ar(tone, pan, amp));
}).send
)
(
Pbind(\freq, Pseq(~notes,1), \dur, 0.2, \instrument, \primeSynth).play;
Pbind(\freq, Pseq(~notes,1), \dur, 0.2, \instrument, \tonalSynth).play;
)

~herb = Buffer.read(s, "/Users/mciul/Music/samples/han_wang_apology.aiff");
~crow = Buffer.read(s, "/Users/mciul/Music/samples/langelliott_american_crow.aiff");
~hotel = Buffer.read(s, "/Users/mciul/Google Drive/samples/hotel_whole.aiff");
~silver = Buffer.read(s, "/Users/mciul/Google Drive/samples/silvermountain_theme_00.aiff");

({
	var b = ~silver;

	var in = Mix(PlayBuf.ar(
		b.numChannels,
		b.bufnum,
		BufRateScale.kr( b.bufnum ),
		loop: 1
	))/b.numChannels.sqrt;
	var mouse_pos = [MouseX.kr(0,1), MouseY.kr(0,1)].poll(1);
	var window = ~notes.collect({|f, i|
		(((i/~notes.size)>mouse_pos[0]) +
		((i/~notes.size)>mouse_pos[1]) +
			(mouse_pos[0]>mouse_pos[1])).wrap(0,2.0)
	});
	var filterbank = BPF.ar(in, ~notes, ~notes.collect({|f, i| 1/(i+1)}));
	var vocoder = A2K.kr(Amplitude.ar(filterbank,
		attackTime: window.madd(-20,20 + (2/~notes)),
		releaseTime: window.madd(-5,5 + (6/~notes))));
	//DynKlang.ar(`[~notes, vocoder.rotate(-3).madd(MouseY.kr(0,10)).wrap(0,MouseX.kr(0.01,0.1)), nil]);
	//DynKlang.ar(`[~notes, vocoder.madd(10000,MouseX.kr(-300,0)).distort.madd(0.05,0.05), nil],MouseY.kr(0.25,2));
	//DynKlang.ar(`[~notes, vocoder, nil], SinOsc.ar(MouseX.kr(0,1000),0,MouseY.kr(0,1),1));
	Poll.kr(Impulse.kr(1), window[58], \window58);
	DynKlang.ar(`[~notes, vocoder, nil]);
}.play
)

2.wrap(0,2.0)
s.prepareForRecord;
s.record;
s.stopRecording;

[1,2,3,4].scramble
~herb
(13*9*7*5*3*2*3).factors
(2*9*7*3*3*13*5).factors
[10,12,11,12].collect(~notes[_])
Pbind(\freq,
s.boot
[1,2,3].includes(7)
20.cpsmidi
15.midicps

	60/12
	{Saw.ar(60.midicps, EnvGen.kr(Env.perc))}.play