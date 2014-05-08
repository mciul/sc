(
{
	loop({
		play ({
			var freq=60.rand.midicps;
			var partials = (20000/freq).asInteger.prevPrime.indexOfPrime.collect({|n| n.nthPrime}) * freq;
			Pan2.ar(Klang.ar(`[partials, nil, nil])) * EnvGen.kr(Env.sine(4), 1, 0.02, doneAction:2);
		});
		2.wait;
	})
}.fork;
)

(
{
			var freq=5;
			var partials = (20000/freq).asInteger.prevPrime.indexOfPrime.collect({|n| n.nthPrime}) * freq;
			Pan2.ar(Klang.ar(`[partials, nil, nil])) * EnvGen.kr(Env.sine(4), 1, 0.02, doneAction:2);
}.plot;
)

(
{
loop({
    play({
        Pan2.ar(Klang.ar(`[ Array.rand(12, 200.0, 2000.0), nil, nil ], 1, 0), 1.0.rand)
             * EnvGen.kr(Env.sine(4), 1, 0.02, doneAction: 2);
    });
    2.wait;
})
}.fork;
)