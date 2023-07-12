

















Ndef(\t, {

	var sig = SoundIn.ar(0);
	sig = CombC.ar(sig, 0.1,SinOsc.kr(LFNoise1.kr(0.2).range(0.0001,0.01)).range(0.001,0.1), 8, 0.1,sig*0.9);
	sig = FreeVerb.ar(sig, 0.5, 0.7, 0.6);
	Out.ar(2, sig);

}).play;



