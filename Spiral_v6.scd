/*
morse frequency with USB
10108.46
10111.18


14073.47

CW
simple morse code
10111.26
10122.97
10123.02

complex morse code
10100.83

aether noise
10136.47

14073.47

*/

(
//fork{

(
Ndef('granulate_input').addSpec(
	// \recLevel, [0,1],
	// \preLevel, [0,1],
	\feedback, [-2.0,2],
	\inAmp, \inAmp,
	\wet, \bipolar,
	\inputAmp, [0,30],
	\tFreqMF, [0,200],
	\tFreqMD, [0,200],
	\offsetMF, \widefreq,
	\offsetMD, [0.0,1],
	\rateMF, \widefreq,
	\rateMD, [0.0,1],
	\offset, [0.0,1],
	\rate, \bipolar,
	\tFreq, [1,22050, \exp],
	\overlap, [0.01,512.0, \exp],
	\grHpf, \freq,
	\grLpf, \freq,
	\wet, [0.0,1],
	\dry, [0.0,1],
	\outAmp, [0.0,4],
);
);

s.scope(index:2, numChannels: 2);
Ndef('granulate_input').clear;
	Ndef('granulate_input').ar(2);
Ndef('granulate_input').edit;


(
Ndef('granulate_input', {|
	input1=4, input2=5, recGate=1,
	inAmp=1, outAmp=1, overlap=3, tFreq=20, tFreqMF=0, tFreqMD=0,
	rate=1, rateMF=0, rateMD=0,
	offset = 0, offsetMF=0, offsetMD=0|

	var input;
	var gDur, readPos, signal, writePos, grained, balance;

	var t, bufFrames, bufRateScale;
	var buf, bufdur;

	var tFreqMod = {
		SinOsc.ar(tFreqMF, Rand(0.0,2pi)) * tFreqMD;
	};

	var rateMod = {
		SinOsc.ar(rateMF, Rand(0.0,2pi)).range(rateMD.neg, rateMD);
		// SinOsc.ar(rateMF, Rand(0.0,2pi)).range(0, rateMD);
	};

	var offsetMod = {
		SinOsc.ar(offsetMF, Rand(0.0,2pi)).range(0, offsetMD);
		// LFDNoise3.ar(offsetMF).range(0,offsetMD(0.0))
	};


	tFreq = tFreq + tFreqMod.dup;
	rate = rate - rateMod.dup;


	bufFrames = 2**16;
	buf = {LocalBuf(bufFrames).clear}!2;
	bufdur = BufDur.ir(buf);


	writePos = Phasor.ar( end: bufFrames );


	t = Impulse.ar(tFreq);


	readPos =
	writePos
	- 64 // looks like a controlblocksize ------ why?
	/ bufFrames
	- offset
	- offsetMod.dup;
	// readPos = readPos.clip( 0, bufFrames - 64 / bufFrames );

	readPos = Wrap.ar(readPos, 0, 1);

/*
	(
		offset * bufFrames + 64 / SampleRate.ir
	).poll(10, \delaytime);
*/



	grained = GrainBufJ.ar(
		numChannels:1,
		loop: 1,
		trigger:t,
		dur: overlap / tFreq,
		sndbuf: buf,
		rate: rate,
		pos: readPos,
		interp: 4,
		pan: 0,
		envbufnum:-1
	);


	grained  = HPF.ar( grained, \grHpf.kr(40) );
	grained  = LPF.ar( grained, \grLpf.kr(15000) );




	input = SoundIn.ar([input1,input1]) * inAmp * recGate;

	// writing granulated + input back to grain buffer
	buf.do { |b i|

		BufWr.ar(grained[i] * \feedback.kr(0.3) + input[i], b, writePos)

		// RecordBuf has an option to overdub, might be of any use for big mess
		// RecordBuf.ar(
		// 	grained[i] * \feedback.kr(0.3) + input[i],
		// 	b,
		// 	recLevel: \recLevel.kr(1),
		// 	preLevel: \preLevel.kr(0),
		// );

	};
	signal = Mix([
		grained * \wet.kr(1),
		input * \dry.kr(1)
	]) * outAmp;

	signal.tanh;
	signal = Mix(signal);
	//Out.ar(0, signal.tanh);

});

);

//2.0.wait;

(
Ndef('barr_verb_one').ar(2);
Ndef('barr_verb_one', { arg
	mix=0.1,
	inAmp=0.8,
	scaleDelays=1,
	inDiffusion=0.05,
	feedback=0.5,
	decay_sec=0.5,
	decay1_sec=0.5;

	//var input1 = \in.ar(0!2)!2;
	var signal;
	var signalIn = [ \in1.ar([0]), \in2.ar([0])] ++ DC.ar(0).dup(3);
	//var signalIn = SoundIn.ar( (0..3) ) * inAmp;
	//var signalIn = input1 * inAmp;
	//var signalIn = [ Impulse.ar(0.5)* inAmp;  ] ++ DC.ar(0).dup(3);
	var tank;
	var sr = SampleRate.ir, sz = 4;
	var src, localin;
	var  times, dtimes;
	var l,r;
	var earlyDiffDTimes, earlyDiffSize=4;

	// signalIn = signalIn.rotate(3);

	// signalIn.debug(\signalIn________________);

	src = HPF.ar(signalIn, \inputHPF.kr(150));
	src = OnePole.ar(src, \inputLPF.kr(0.5));

	src = DelayN.ar(src, 0.1, \predelay.kr(0.0));

	times = [ 1447, 727, 613, 673, 1439, 2083, 2011, 1511, 1493, 1277, 2437, 2383, 2341, 997, 1061, 2039, 1997, 1481, 1627, 1129, 743, 983, 1091, 907, 541, 2393, 1801, 2081, 1787, 1453, 977, 2311, 691, 479, 2377, 1693, 1013, 1931, 1049, 2243, 839, 739, 1747, 601, 1823, 1123, 2467, 1297, 1613, 1361, 2207, 593, 619, 1709, 449, 937 ];




	earlyDiffDTimes = { times.removeAt(times.minIndex) } ! ( earlyDiffSize * src.size );

	l = times.size.div(2).collect({|i| times[i*2]}) * scaleDelays;
	r = times.size.div(2).collect({|i| times[i*2 + 1]}) * scaleDelays;




	dtimes = Routine{(earlyDiffDTimes ++ l ++ r).do { |it|it.yield}};
	// dtimes = Pseq( earlyDiffDTimes ++ l ++ r ).asStream;




	src.do { |it i|
		earlyDiffSize.do {
			var dt = dtimes.next / sr;
			src[i] = AllpassN.ar(src[i], dt, dt, inDiffusion);
		};

	};

	localin = LocalIn.ar(1);

	tank = sz.collect { |i|
		var dt0, dt1, dt2;

		localin = localin + src[i];

		dt0 = dtimes.next / sr;
		dt1 = dtimes.next / sr;
		dt2 = dtimes.next / sr;

		localin = AllpassC.ar(localin, dt0, dt0, decay_sec );
		localin = AllpassC.ar(localin, dt1, dt1, decay1_sec);


		localin = DelayC.ar(localin, dt2, dt2 - ( ControlDur.ir / sz )* LFNoise2.kr(0.3).range(0.9,1));

		localin = OnePole.ar(localin, \damping.kr(0.0) );

		// localin = localin * feedback;

	};


	tank.debug(\tank);

	LocalOut.ar( tank.last * feedback;);


	signal = 2.collect({|i|
		i = i*2;
		[
			tank[i] * ( "level_" ++ i ).asSymbol.kr(0),
			tank[i+1] * ( "level_" ++ ( i+1 ) ).asSymbol.kr(0)
		]
	}).sum;




	// signal = tank.sum;
	signal = LeakDC.ar(signal);

	// signal.debug(\signal);
	signal * \tail.kr(1);

	signal = (signal * mix ) + (( signalIn!2) * (1-mix));





}
	// .draw
).edit;
);

Ndef( 'barr_verb_one' ).addSpec(
	\mix, [0.0,1.0,\lin],
	\predelay, [0.0,0.1,\lin],
	\inDiffusion, [0.001,3,\exp],
	\tail, \unipolar,
	\feedback, \unipolar,
	\inputLPF, \unipolar,
	\inputHPF,\freq,
	\peakgain, [-6.0,6.0, \lin, 0.001,0],
	\rqscale, [0.5,2],
	\level_0, \bipolar,
	\level_1, \bipolar,
	\level_2, \bipolar,
	\level_3, \bipolar,
	\decay_sec, [0.0,5],
	\decay1_sec, [0.0,5],
	\damping, [0.0,1],
);


Ndef( 'barr_verb_one' ).play;

Ndef('barr_verb_one').set('damping', 0.35449735449735, 'level_1', 1.0, 'tail', 1.0, 'inputLPF', 0.12169312169312, 'inDiffusion', 0.36078452971593, 'level_2', 0.079365079365079, 'level_3', 0.058201058201058, 'decay_sec', 0.37037037037037, 'inputHPF', 35.892048805946, 'decay1_sec', 0.29100529100529, 'feedback', 0.95238095238, 'level_0', -0.87301587301587);


/*guitar*/
Ndef('barr_verb_one').set('damping', 0.35449735449735, 'level_1', 1.0, 'tail', 1.0, 'inputLPF', 0.12169312169312, 'inDiffusion', 0.36078452971593, 'level_2', 0.079365079365079, 'level_3', 0.058201058201058, 'decay_sec', 0.37037037037037, 'inputHPF', 35.892048805946, 'decay1_sec', 0.29100529100529, 'feedback', 0.95238095238, 'level_0', -0.87301587301587);


/*recorder*/
Ndef('barr_verb_one').set('damping', 0.35449735449735, 'level_1', 1.0, 'tail', 1.0, 'inputLPF', 0.12169312169312, 'inDiffusion', 0.36078452971593, 'level_2', 0.079365079365079, 'level_3', 0.058201058201058, 'decay_sec', 0.8037037037037, 'inputHPF', 35.892048805946, 'decay1_sec', 0.29100529100529, 'feedback', 0.75238095238, 'level_0', -0.87301587301587);


Ndef(\barr_verb_one) <<>.in1 Ndef('granulate_input');
Ndef(\barr_verb_one) <<>.in2 Ndef('granulate_input');



MIDIIn.connectAll;

//2.0.wait;

~overlap_spec = [0.01,5.0,\exp,0.001].asSpec;
~tfreq_spec = [22050*0.001,1,-4,0.001].asSpec;
~offset_spec = [0.01,1,\linear,0.001].asSpec;

~ratemf_spec = [0.0,2000,\linear,0.001].asSpec;
~ratemd_spec = [0.0,1.0,\linear,0.001].asSpec;
~trigmf_spec = [0.01,200,\linear,0.001].asSpec;
~trigmd_spec = [0.01,200,\linear,0.001].asSpec;

~recinput_switch = 0;
~grain_settings = 0;
(
MIDIdef.cc(\nanoKtest, {| val num chan src|
	[num,val, src].postln;

	case
	//button for changing recinput
	{ num == 16 }
	{
		if ( ~recinput_switch != 2, { ~recinput_switch = ~recinput_switch + 1; }, { ~recinput_switch = 0; });

		case
		{ ~recinput_switch == 0 } { "radio".postln;
			Ndef('granulate_input').set(\input1, 4, \input2, 5); }
		{ ~recinput_switch == 1 } {"guitar".postln;
			Ndef('granulate_input').set(\input1, 0, \input2, 0);

		}
		{ ~recinput_switch == 2 } { "recorder microphone".postln;
			Ndef('granulate_input').set(\input1, 2, \input2, 2); };

	}
	//button for settings bar 4
	{ num == 17 }
	{
		if ( ~grain_settings != 3, { ~grain_settings = ~grain_settings + 1; }, { ~grain_settings = 0; });

		case
		{ ~grain_settings == 0 } { "2 - fragmented, high".postln;
			Ndef('granulate_input').set('offset', 0.158, 'wet', 0.8503937007874, 'rate', 2.2493240605221, 'tFreq', 1.0, 'grLpf', 18851.464465481, 'rateMF', 20.472, 'tFreqMF', 17.884, 'tFreqMD', 0.1, 'rateMD', 0.5, 'overlap', 5.0, 'dry', 0.1496062992126, 'feedback', 0.5);
		}

		{ ~grain_settings == 1 }  {" 1 - bar 3".postln;
			Ndef('granulate_input').set('offset', 0.189, 'wet', 0.5511811023622, 'rate', 2.2493240605221, 'tFreq', 397.379, 'grLpf', 18851.464465481,  'rateMF', 20.472,'tFreqMF', 17.884, 'tFreqMD', 0.1, 'rateMD', 0.5, 'overlap', 0.121, 'dry', 0.4488188976378, 'feedback', 0.5); }
		{ ~grain_settings == 2 } { "2 - bar 4".postln;
			Ndef('granulate_input').set('offset', 0.1, 'wet', 1.0, 'rate', 0.25035754779845, 'tFreq', 4.127, 'grLpf', 18851.464465481, 'rateMF', 220.472, 'tFreqMF', 7.884, 'tFreqMD', 0.01,'rateMD', 0.0, 'overlap', 2.072, 'dry', 0.0, 'feedback', 0.84928932685149);
		}
		{ ~grain_settings == 3 } {   "0 - normal setting".postln;
			Ndef('granulate_input').set('offset', 0.158, 'wet', 1.0, 'rate', 1.01, 'tFreq', 14.127, 'grLpf', 18851.464465481, 'rateMF', 0.0, 'tFreqMF', 0.01, 'tFreqMD', 0.01,'rateMD', 0.0, 'overlap', 0.8, 'dry', 0.0, 'feedback', 0.34928932685149);
		};


	}
	//button for switching rec on / off
	{ num == 24 }
	{
	if ( val == 0, {
			"recgate off".postln;
			Ndef('granulate_input').set(\recGate, 0);

		},
		{
			"recgate on".postln;
			Ndef('granulate_input').set(\recGate, 1);
		});

	}
	//granular
	{ num == 0 }
	{
		Ndef(\granulate_input).set(\dry, (val/127) , \wet, (1 - (val/127) ));
	}
	{ num == 1 }
	{
		Ndef('barr_verb_one').set('mix', (val/127) );

	}

	{ num == 32 } {
		Ndef(\granulate_input).set(\overlap, ~overlap_spec.map(val/127), \tFreq, ~tfreq_spec.map(val/127); ); }
	{ num == 33 } {
		Ndef(\granulate_input).set(\offset, ~offset_spec.map(val/127) ); }
	{ num == 34 } {
		Ndef(\granulate_input).set(\rateMF, ~ratemf_spec.map(val/127) ); }
	{ num == 35 } {
		Ndef(\granulate_input).set(\rateMD, ~ratemd_spec.map(val/127) ); }
	{ num == 36 } {
		Ndef(\granulate_input).set(\tFreqMF, ~trigmf_spec.map(val/127) ); }
	{ num == 37 } {
		Ndef(\granulate_input).set(\tFreqMD, ~trigmd_spec.map(val/127) ); };



}, srcID:2097152);


MIDIdef.cc(\BOSS_footpedal, {| val num chan src|
	[num,val,chan, src].postln;

	case
	{ num == 11 } {
		Ndef(\granulate_input).set(\overlap, ~overlap_spec.map(val/127), \tFreq, ~tfreq_spec.map(val/127); ); }

},srcID:8388608);


);


//}
);


Ndef('granulate_input').set(\rate, 0.25);

