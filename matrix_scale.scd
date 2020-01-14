s.boot;
76.midicps
(76-36-8).midicps
(
SynthDef(\distortRes, {
	arg in=0, out=0, maxdelaytime=0.2, latency=ControlRate.ir.reciprocal, delaytime=440.reciprocal, gain=1, amp=1;
	var sig;
	sig = In.ar(in).madd(gain).softclip;
	sig = DelayL.ar(sig, maxdelaytime, delaytime.reciprocal - latency, amp);
	Out.ar(out, sig);
});

SynthDef(\feedbackGate, {
	arg in=0, out=0, amp=0.3, gate=0;
	var sig;
	sig = FeedbackIn.ar(in) * EnvGen.ar(Env.adsr(sustainLevel:1, releaseTime:0.2), gate, amp, doneAction:2);
	Out.ar(out, sig);
});
)

/*
(44100/64).cpsmidi ~= 76.77

[(1/4), (1/8)] -> 3/8
[(1/4), (1/6)] -> 5/12
[(1/4), (1/5)] -> 9/20
[(1/3), (1/6)] -> 1/2
[(1/3), (1/5)] -> 8/15
[(1/3), (1/6), (1/8)] -> 5/8
[(1/2), (1/8)] -> 5/8
[(1/2), (1/6)] -> 2/3
[(1/2), (1/4)] -> 3/4
[(1/3), (1/4), (1/6)] -> 3/4
[(1/2), (1/3)] -> 5/6
[(1/2), (1/3), (1/6)] -> 1/1
[(1/2), (1/3), (1/6), (1/8)] -> 9/8
[(1/2), (1/3), (1/5), (1/6)] -> 6/5
[(1/2), (1/3), (1/4), (1/6)] -> 5/4

longer version:
(1/8).reciprocal.ratiomidi // = +36 semitones
(1/6).reciprocal.ratiomidi // = +31.019550008654 semitones
(1/4).reciprocal.ratiomidi // = +24 semitones
(7/24).reciprocal.ratiomidi.mod(12) // 1/6 + 1/8 = + (21.331290943962625) semitones
(13/40).reciprocal.ratiomidi.mod(12) // 1/5 + 1/8 = + (19.457860520955244) semitones
(1/3).reciprocal.ratiomidi // = +19.019550008654 semitones
(11/30).reciprocal.ratiomidi.mod(12) // 1/5 + 1/6 = + (17.36950772365466) semitones
(3/8).reciprocal.ratiomidi.mod(12) // 1/4 + 1/8 = + (16.980449991346124) semitones
(5/12).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 = + (15.156412870005525) semitones
(9/20).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 = + (13.8240371213406) semitones
(11/24).reciprocal.ratiomidi.mod(12) // 1/3 + 1/8 = + (13.50637058500631) semitones
(1/2).reciprocal.ratiomidi.mod(12) // 1/2 = + (12.0) semitones
(8/15).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 = + (10.88268714730222) semitones
(13/24).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 + 1/8 = + (10.614273390960768) semitones
(7/12).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 = + (9.331290943962623) semitones
(5/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/8 = + (8.136862861351654) semitones
(2/3).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 = + (7.019550008653875) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/6 = + (6.174878073957099) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 = + (6.174878073957099) semitones
(3/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 = + (4.980449991346124) semitones
(19/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 + 1/8 = + (4.04441984733085) semitones
(5/6).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 = + (3.1564128700055254) semitones
(7/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/8 = + (2.31174093530875) semitones
(19/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 = + (0.8880069773253213) semitones
(1/1).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 = + (0.0) semitones
(13/12).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 = + (-1.3857266090392308) semitones
(9/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 + 1/8 = + (-2.0391000173077494) semitones
(6/5).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 = + (-3.1564128700055254) semitones
(5/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 = + (-3.8631371386483475) semitones
(53/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 + 1/8 = + (-4.871908316110041) semitones
(11/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 + 1/8 = + (-5.513179423647567) semitones
(29/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 = + (-6.432634802882516) semitones
(63/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 + 1/8 = + (-7.8642219433506515) semitones

full version:
(7/24).reciprocal.ratiomidi.mod(12) // 1/6 + 1/8 = + (21.331290943962625) semitones
(13/40).reciprocal.ratiomidi.mod(12) // 1/5 + 1/8 = + (19.457860520955244) semitones
(11/30).reciprocal.ratiomidi.mod(12) // 1/5 + 1/6 = + (17.36950772365466) semitones
(3/8).reciprocal.ratiomidi.mod(12) // 1/4 + 1/8 = + (16.980449991346124) semitones
(5/12).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 = + (15.156412870005525) semitones
(9/20).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 = + (13.8240371213406) semitones
(11/24).reciprocal.ratiomidi.mod(12) // 1/3 + 1/8 = + (13.50637058500631) semitones
(59/120).reciprocal.ratiomidi.mod(12) // 1/5 + 1/6 + 1/8 = + (12.29097055496013) semitones
(1/2).reciprocal.ratiomidi.mod(12) // 1/3 + 1/6 = + (12.0) semitones
(8/15).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 = + (10.88268714730222) semitones
(13/24).reciprocal.ratiomidi.mod(12) // 1/4 + 1/6 + 1/8 = + (10.614273390960768) semitones
(23/40).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 + 1/8 = + (9.580393665964195) semitones
(7/12).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 = + (9.331290943962623) semitones
(37/60).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 + 1/6 = + (8.369246759754825) semitones
(5/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/8 = + (8.136862861351654) semitones
(5/8).reciprocal.ratiomidi.mod(12) // 1/3 + 1/6 + 1/8 = + (8.136862861351654) semitones
(79/120).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/8 = + (7.237318169176989) semitones
(2/3).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 = + (7.019550008653875) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/6 = + (6.174878073957099) semitones
(7/10).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 = + (6.174878073957099) semitones
(17/24).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/8 = + (5.969995913649799) semitones
(89/120).reciprocal.ratiomidi.mod(12) // 1/4 + 1/5 + 1/6 + 1/8 = + (5.173885975705449) semitones
(3/4).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/6 = + (4.980449991346124) semitones
(3/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 = + (4.980449991346124) semitones
(47/60).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 = + (4.227620927170575) semitones
(19/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/6 + 1/8 = + (4.04441984733085) semitones
(33/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 + 1/8 = + (3.3304077063469073) semitones
(33/40).reciprocal.ratiomidi.mod(12) // 1/3 + 1/5 + 1/6 + 1/8 = + (3.3304077063469073) semitones
(5/6).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 = + (3.1564128700055254) semitones
(13/15).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 + 1/6 = + (2.4774105296091147) semitones
(7/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/8 = + (2.31174093530875) semitones
(7/8).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/6 + 1/8 = + (2.31174093530875) semitones
(109/120).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 + 1/8 = + (1.6644752499791071) semitones
(11/12).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/6 = + (1.5063705850063096) semitones
(19/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 = + (0.8880069773253213) semitones
(19/20).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 + 1/6 = + (0.8880069773253213) semitones
(23/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/8 = + (0.7368065359697193) semitones
(119/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/5 + 1/6 + 1/8 = + (0.14487398760689965) semitones
(1/1).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 = + (0.0) semitones
(31/30).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 = + (-0.5676685773402816) semitones
(25/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/6 + 1/8 = + (-0.7067242686428228) semitones
(43/40).reciprocal.ratiomidi.mod(12) // 1/3 + 1/4 + 1/5 + 1/6 + 1/8 = + (-1.2520399177768273) semitones
(43/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 + 1/8 = + (-1.2520399177768273) semitones
(13/12).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 = + (-1.3857266090392308) semitones
(67/60).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 + 1/6 = + (-1.9103831381910463) semitones
(9/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/6 + 1/8 = + (-2.0391000173077494) semitones
(139/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/8 = + (-2.544605725379868) semitones
(6/5).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 = + (-3.1564128700055254) semitones
(29/24).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/8 = + (-3.2762219328769895) semitones
(149/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/4 + 1/5 + 1/6 + 1/8 = + (-3.7473350982437177) semitones
(5/4).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 = + (-3.8631371386483475) semitones
(77/60).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 = + (-4.318751341036596) semitones
(53/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/5 + 1/6 + 1/8 = + (-4.871908316110041) semitones
(11/8).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/6 + 1/8 = + (-5.513179423647567) semitones
(169/120).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/8 = + (-5.9278660880839915) semitones
(29/20).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 = + (-6.432634802882516) semitones
(63/40).reciprocal.ratiomidi.mod(12) // 1/2 + 1/3 + 1/4 + 1/5 + 1/6 + 1/8 = + (-7.8642219433506515) semitones
*/
(20/9).ratiomidi.mod(12)
