Beets
=====

A little iPhone utility that listens to music through the mic or Audiobus and displays its BPM.

BPM detection is implemented using the [Aubio](http://aubio.org) audio analysis library. Before building, you'll need to download the iOS framework from http://aubio.org/download and put `aubio.framework` into the Beets directory.

To build with Audiobus support, download the Audiobus SDK, place it inside the Beets folder as "Audiobus-SDK" and then build the "with Audiobus" target in Beets.xcodeproj. You'll get a parse error on `AUDIOBUS_API_TOKEN_HERE`, replace that with your Audibus app token and it should work.



![Screenshot](http://d.asgeirsson.is/1hl3S.png)