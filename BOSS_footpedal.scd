/*ON UBUNTU OR LINUX: install BLUEZ with MIDI SUPPORT
URL: https://tttapa.github.io/Pages/Ubuntu/Software-Installation/BlueZ.html

deze is beter:
https://codeberg.org/plenae/ubuntu-bluez-with-midi

bluez midi kept on de-installing
probeer nu deze:
apt-mark hold <package_name>

IN CASE OF ERROR WITH CONFIGURE
adding
#include <linux/sockios.h>
to the include section of BlueZ
tools/l2test.c and tools/rctest.c
solved the issue.

*/



MIDIIn.connectAll;

MIDIdef.cc(\test3, {arg ...args; args.postln}); // match cc 1-10


MIDIdef.cc(\BOSS_footpedal, {| val num chan src|
	[num,val,chan, src].postln;

},srcID:8388608);




MIDIdef.cc(\nanoKtest).free

c = MIDIFunc.cc({arg ...args; args.postln}, (1..100));