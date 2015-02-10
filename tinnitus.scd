s.boot
{Pan2.ar(SinOsc.ar(MouseX.kr(5000,20000,1)),MouseY.kr(-1,1),0.1)}.play

{SinOsc.ar(MouseX.kr(5000,20000,1),0,[0,0.1])}.play

{f=MouseY.kr(5e3,12000,1).poll(1);Pan2.ar(SinOsc.ar(f),MouseX.kr(-1,1).poll(1),f/5e4)}.play


5000.cpsoct
5e3
15000.cpsoct

1.5e4

13000/2e4

{f=9513.06;Pan2.ar(SinOsc.ar(f),-0.3,f/1e5)}.play
{f=10205;Pan2.ar(SinOsc.ar(f),-0.1,f/2e4)}.play
{f=7620.88;Pan2.ar(SinOsc.ar(f),0.2,f/1e5)}.play
{f=8562.04;Pan2.ar(SinOsc.ar(f),0.5,f/1e5)}.play
{f=5726.5;Pan2.ar(SinOsc.ar(f),0.7,f/6e4)}.play

[6323,9513,10205,7621,11732,8562,5727]

{n=LFNoise1;f=[63,102,76,117,86,57]*100;Pan2.ar(SinOsc.ar(n.kr(f/40000,f/20,f)),n.kr([1,3,2,4,5,6]),n.kr(10000/f,0.04,[2,10,1,15,1,3]/50))}.play // based on crazy "tinnitus cure" description

{f=[63,102,76,117,86,57]*100;CombC.ar(Pan2.ar(SinOsc.ar(LFNoise1.kr(f/40000, f/20, f)), LFNoise1.kr([0.5,0.49,0.47,0.48,0.51,0.53]), LFNoise1.kr([3.5,3.3,3.1,3.2,3.4],0.06 ,-0.02).clip(0,0.2)).sum,2,LFNoise1.kr([0.5,0.6],0.5,1.5),10)}.play

{n=LFNoise1;f=[63,102,76,117,86,57];Splay.ar(SinOsc.ar(f*MouseY.kr(50,150),0,n.kr(1/f,2,[1,9,1,9,1,2])/100))}.play // my tinnitus #sctweets

[2,1,9,2,9,1,3]/100
1/100
0.01
1e-2
().midicps
-1.clip(0,0.2)
5000.cpsmidi
12000.cpsmidi
0.02*5
5/250
5*0.004
5*4e-3
9/200
1/200
([63,102,76,117,86,57]*100)/1000
s.scope(2)