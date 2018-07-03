82.41.cpsmidi // midi note 40 - 10f (5x1) E + 0
(40.midicps / 10 * 12).cpsmidi // midi note 43.16 12f (3x1) G + .16
(40.midicps / 10 * 15).cpsmidi // midi note 47.02 15f (3x5) B + 0.02
(40.midicps / 10 * 21).cpsmidi // midi note 52.84 21f (3x7) F - 0.16
(40.midicps / 10 * 28).cpsmidi // midi note 57.83 28f (7x1) Bb - 0.17
(40.midicps / 10 * 35).cpsmidi // midi note 61.69 35f (7x5) D - 0.31

s.boot;
{SinOsc.ar(40.midicps, 0, [1,1])}.play
{SinOsc.ar((40.midicps / 10 * 12), 0, [1,1])}.play
{SinOsc.ar((40.midicps / 10 * 15), 0, [1,1])}.play
{SinOsc.ar((40.midicps / 10 * 21), 0, [0.5,0.5])}.play
{SinOsc.ar((40.midicps / 10 * 28), 0, [0.25,0.25])}.play
{SinOsc.ar((40.midicps / 10 * 35), 0, [0.25,0.25])}.play


s.scope