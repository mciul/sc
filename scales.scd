s.boot

[1,4,4,2,1].normalize

29.midicps; // F1
57.midicps/5; // two octaves and a third down from A3

43.midicps; // G2
81.midicps/9; // three octaves and a whole town down from A5

(
g=[1,2,3,4]*(81.midicps/9);//43.midicps);
f=[2,3,4,5,6]*(57.midicps/5);//29.midicps);
~bass=Pbind(\freq, Pwalk([g,f].flatten.sort, stepPattern:Pwrand([-2,-1,0,1,2,3], [1,4,2,4,2,1].normalizeSum, inf),directionPattern:-1),
\dur, 0.4, \amp, 0.5);

x=[5,6,7,8,9]*(81.midicps/9);//43.midicps);
y=[7,8,9,10,11,12]*(57.midicps/5);//29.midicps);
~treble=Pbind(\freq, Pwalk([x,y].flatten.sort, stepPattern:Pwrand([-3,-1,0,2,3,5], [1,4,3,4,2,1].normalizeSum, inf),directionPattern:-1),
	\dur, 0.2, \amp, 0.2, \pan, Pxrand([-0.5,0,0.5],inf));

p = Ppar([~bass, ~treble, ~treble]).play;
)

Pbind(\freq, Pseq([(2..12)*(29.midicps), ((2..12)*(57.midicps)/5)].flop, inf), \dur, 0.2).play

((0..10)*29).postln

a = (0..10);

[[1,2],[3,4]].flop
