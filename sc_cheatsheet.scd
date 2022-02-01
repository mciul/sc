// Supercollider cheat sheet

// cmd-D - show documentation for selection
// cmd-Enter - execute selection
// cmd-B - expand selection to the next bracket level

// controlling the server

Server // highlight and hit cmd-D to see the doc page


s.boot
s.quit
s.scope

// Language

// Global variables - single letters or strings starting with ~
//
// sc has classes, but they must be compiled
// However, functions can be created in the runtime environment
// Functions are objects, like in Smalltalk
// Curly brackets define an an anonymous function
// The last expression evaluated is the return value

{ |num| num + 1 };

// To name a function, assign it to a variable

f = { |num| num + 1 };

// To execute a function, use the .value method;

f.value(13);

// The last value evaluated is written to the post window

// To output something to the post window, use the .post and .postln methods

"hello world".postln;
f.postln;
f.value(11).postln;

// Another cool function method is .play:

{ SinOsc.ar(freq: 220, mul: 0.2) }.play;

// To stop all synths that are playing, hit cmd-period

// The play method returns a synth that you can control:

x = { SinOsc.ar(freq: 220, mul: 0.2) }.play;

x.free;

// The sc language is for the client only. It sends OSC messages to the sc server.
// You can have other clients - they don't need to use the sc language

// Synths are made with UGens (Unit Generators).
// UGen is a class representing a composable wavefunction generator

// The main constructors for UGens are .ar (audio rate) and .kr (control rate)
// By default, the control rate of the sc server is 1/64 the audio rate
// It generates audio in chunks of 64 samples at a time

// This limits the opportunity for feedback - if you plug the output of a UGen
// into a feedback loop, there will always be a delay of 64 samples or more

// Many UGen constructors have an audio input parameter, which can be another UGen

{ Impulse.ar(freq:3) }.play // a click

{ CombN.ar(Impulse.ar(freq:3), delaytime: 1/220, decaytime: 1/3) }.play; // a resonator

// numbers are objects in sc too. They have the standard object methods like .postln, plus
// many others:

-11.abs
440.cpsmidi // what MIDI note number is A440?
3.do( { |i| "Iteration number ".post; i.postln } ); // this one takes a function as argument

// sc has lots of Collection objects, and as you might expect,
// they have lots of iterative methods
(2..6).do( { |i| "i=".post; i.postln; } );
(2..6).collect( { |i| i*2 } );
(2..6).select( { |i| i.mod(2) == 0 } );
(2..6).inject(0, { |a,b| a + b }); // inject is a left fold
(2..6).sum; // but we can let sc do that one for us

// when binary operators take a collection and a number, it applies the number to each item
[ 2,3,5,7 ] * 3;

// with two arrays, it pairs the elements, looping the shorter one:
[ 0,1,2,3 ] * [ 1, 1, 2, 2, 100, 100, 100, 100 ]

// if you want to get a cartesian product, you have to iterate and then flatten:

[1, 2].collect({ |i| [3, 4].collect({ |j| [i, j]}) });
[1, 2].collect({ |i| [3, 4].collect({ |j| [i, j]}) }).flatten;

// sc does have list comprehensions but I've never seen anyone use them:

{:[i, j], i <- [1, 2], j <- [3, 4] }.all;

// conditionals in sc take an expression and two functions

if( 1 == 1, { "trivial".postln; }, { "unexpected".postln; } );
if( 2 + 2 == 5, { "gaslighting".postln; }, { "sensible".postln; } );

// this is actually alternate syntax for a method of the Boolean class -
// sc allows any method to be written as a "function call" with the receiver as
// as the first argument.

true.if({"you got me".postln; }, {"missed!".postln});


