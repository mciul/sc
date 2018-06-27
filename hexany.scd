(
[[20, 21], [21, 24], [24, 28], [28, 30], [30, 35], [35, 40]].collect { |freqs|
	a=freqs[0].post;
	"-".post;
	b=freqs[1].post;
	": ".post;
	(1.0*b/a).ratiomidi.postln;
}
)