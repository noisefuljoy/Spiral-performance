/*ON UBUNTU OR LINUX: install BLUEZ with MIDI SUPPORT
URL: https://tttapa.github.io/Pages/Ubuntu/Software-Installation/BlueZ.html
*/



MIDIIn.connectAll;

MIDIdef.cc(\test3, {arg ...args; args.postln}); // match cc 1-10


MIDIdef.cc(\BOSS_footpedal, {| val num chan src|
	[num,val,chan, src].postln;

},srcID:8388608);




MIDIdef.cc(\nanoKtest).free

c = MIDIFunc.cc({arg ...args; args.postln}, (1..100));