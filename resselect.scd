(
x = {
    // A collection of different tones:
    var son = SinOsc.ar((100, 100.3 .. 110));
    var val = ArrayMax.ar(son).at(0);
    val = LeakDC.ar(val); // the operation tends to induce DC offset
    Pan2.ar(val)
}.scope
)
x.free

(
Instr(\stereodrone, { arg gain=1, limit_level=0.5, post_gain=0.7;
	var in = SoundIn.ar([0,1]) * gain;
	var measure = 2;
	var notes = [ 48, 43, 46, 51, 41 ].midicps;
	var beats = [1, 0.5];
	var times = beats * measure - ControlRate.ir.reciprocal;
	var decay = (-60 * beats / 2).dbamp;
	var highbustfreq = ZeroCrossing.ar(BPF.ar(LocalIn.ar(2), 5000, 2)).lag(measure);
	var delays = CombN.ar(Notch.ar(in, highbustfreq), [measure * 2, measure/2], [measure * 2, measure/2], measure * 3, add:in);
	var res = delays.collect({|chain, i| CombC.ar(chain, notes.reciprocal, notes.reciprocal, measure)});
	var filtered = LeakDC.ar(LPF.ar(res, 2000)).flop.postln;
	var amp = filtered.collect({ |band| RLPF.ar(Amplitude.ar(band), (measure/[1,8]).reciprocal, 0.5) });
	var val, index, selection, out, resbustfreq;
	# val, index = ArrayMax.ar(amp).flop;
	selection = ([index.at(0), LastValue.ar(index.at(1))] + 1).wrap(0, notes.size - 1);
	resbustfreq = Select.ar(selection, DC.ar(notes)).lag(measure * 8);
	out = SelectX.ar(selection.lag(measure/[4,16]), (filtered.flop * [amp + 0.5, amp * amp * 1800].softclip).flop);
	out = CombC.ar(out, delaytime:resbustfreq.reciprocal, decaytime:-0.5, add:out);
	LocalOut.ar(out);
	Limiter.ar(out, 0.5, [measure/2, measure]) * post_gain;
},
	#[
		\amp,       //gain
		\amp,       //limit_level
		\amp        //post_gain
	]
).gui;
)
y.free
cycle rhythm:

durations: 2, 2, 3, 1, 4
pitch:     4, 2, 1, 5, 3 ?

(-60 * [1, 0.5] /2).dp

440.cpsmidi

[1,2,3].reverse
4+7-12
(
w = {
	var signals = [SinOsc.ar, WhiteNoise.ar, Dust.ar(100)];
	Select.ar(-2.wrap(0, signals.size - 1), signals);
}.scope;
)
w.free;

(
y = {
	var in = SoundIn.ar([0,1]);
	var beat = 0.5;
	var measure = beat * 4;
	var rhythm = [ 8, 4, 6, 5, 8 ] * beat;
	var notes = [ 48, 43, 41, 51, 46 ].midicps;
	var cycle = LocalIn.ar( notes.size * in.size ).clumps([notes.size]);
	var decay = (-90/notes.size).dbamp.poll(1);
	var delay = rhythm - ControlRate.ir.reciprocal;
	var delays = cycle.collect({ |channel, i| LeakDC.ar(DelayN.ar(channel.rotate(1), delay.rotate(i), delay)) });
	var res = delays.collect({|channel| CombC.ar(channel, notes.reciprocal, notes.reciprocal, 3)});
	var filtered = LeakDC.ar(LPF.ar(res, 2000)).flop;
	var amp = RLPF.ar(Amplitude.ar(filtered), (measure/8).reciprocal, 0.3);
	var val, index, freq;
	LocalOut.ar((res * decay + in).flatten);
	# val, index = ArrayMax.ar(amp).flop;
	//freq = ZeroCrossing.ar(Select.ar(index, res)).poll(1, label:\freq);
	SelectX.ar([index, LastValue.ar(index)].lag(0.1), (filtered.flop * [amp + 0.5, amp * amp * 1800].softclip).flop).softclip;
	//SinOsc.ar(freq.lag(0.05), 0, 0.2);
}.scope;
)

	