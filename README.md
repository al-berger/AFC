# Audio Flow Combiner


## Introduction

"Audio Flow Combiner" (AFC) is a program for playing audio files in a programmable and finely controlled way. It can play files by fragments, with pauses, repeatings, audio effects, and with intermingling fragments from several audio files into one audio flow.

AFC plays files via "**SoX**" command line audio program, which is needed to be [downloaded](https://sourceforge.net/projects/sox/files/sox/) in order for AFC to work.

AFC plays files by fragments of user defined length, making between fragments a pause of user defined length, creating an audio flow like this ("Fᵢ" - i-th audio fragment, "\_" - silence ):

F₁ _ F₂ _ F₃ _ ... Fₙ

Each fragment can begin from the time where the previous one ended, or with an offset back or forth in the file.

Fragments can be repeated, where each repetition can be played with different audio effects.This can be useful, for example, in learning languages, where the first time a fragment is played with slow speed, and the second time - with normal speed.

Fragments from several audio files can be played in one flow. For example, speech fragments can alternate with music fragments.

## Audio flow

An audio *flow* is created by defining it in a configuration file. A flow is formed by one or more *streams*. Stream represents an audio file, fragments from which are played. For example, a flow can have two streams representing a speech audio file and a music audio file, and play their fragments interchangeably.

A stream definition contains the audio file name (or a file pattern, for including several files into the stream), and the _fragment_ definition, describing how the file should be divided on audio fragments.

A fragment definition consists of the fragment length, the length of the pause between fragments, and one or more _play_ definitions, describing the audio effects which should be applyed during the fragment's playback. The number of play objects in the fragment definition determines how many times the fragment should be played.

A play definition contains parameters of the fragment's playback and audio effects: volume, playback speed, fade effects, etc.

An example of a configuration file with a definition of a flow containing one stream, no fragment repetitions and minimal audio effects:

```
"play1": {
  class: "Play",
  volume: 0.5,
  fadeIn: 5,
  fadeOut: 5
}

"frag1": {
  class: "Fragment",
  length: 300,
  pause: 1800,
  plays: ["play1"]
}

"stream1": {
  class: "Stream",
  rootDir: "D:/Bach/",
  filePatt: ".\*Cello Suite.\*",
  fragOverlap: 5,
  fragment: "frag1",
}

"5minBreaks": {
  class: "Flow",
  streams: ["stream1"],
}
```

This flow will consist of 5 min fragments, played every 30 min.
