# Audio Flow Combiner

##Table of contents
* [Introduction](#introduction)
* [Audio flow](#audio-flow)
* [Dependencies](#dependencies)
* [Running AFC](#running-afc)
* [Flow configuration](#flow-configuration)

## Introduction

"Audio Flow Combiner" (AFC) is a program for playing audio files in a programmable and finely controlled way. It can play files by fragments, with pauses, repeatings, audio effects, and with intermingling fragments from several audio files into one audio flow.

AFC plays files by fragments of user defined length, making between fragments a pause of user defined length, creating an audio flow like this ("Fᵢ" - i-th audio fragment, "\_" - silence ):

F₁ _ F₂ _ F₃ _ ... Fₙ

Each fragment can begin from the time where the previous one ended, or with an offset back or forth in the file.

Fragments can be repeated, where each repetition can be played with different audio effects.This can be useful, for example, in learning languages, where the first time a fragment is played with slow speed, and the second time - with normal speed.

Fragments from several audio files can be played in one flow. For example, speech fragments can alternate with music fragments.

## Audio flow

An audio *flow* is created by defining it in a configuration file. A flow is formed by one or more *streams*. Stream represents an audio file, fragments from which are played. For example, a flow can have two streams representing a speech audio file and a music audio file, and play their fragments interchangeably.

A stream definition contains the audio file name (or a file pattern, for including several files into the stream), and the _fragment_ definition, describing how the file should be divided into audio fragments.

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

## Dependencies

1. AFC is written in **Transd** programming language and needs a Transd interpreter for running.The FREND command line Transd interpreter can be downloaded [here](https://github.com/transd-lang/frend).

2. AFC plays files via "**SoX**" command line audio program, which is needed to be [downloaded](https://sourceforge.net/projects/sox/files/sox/) in order for AFC to work.

## Running AFC

Once you have defined the details of your audio flow in a flowlist file, you can start to play it. To play the flow, type the following command on the command line:

```
frend "AFC.td"
```

`frend` - is the name of the FREND interpreter's executable file, `"AFC.td"` - is a program file from this distribution. If directories with these files are not in the system PATH list, the file names need to be typed with the full paths.

The above command will start the flow that has the default name in the flowlist file. To start a flow with other name, the command should be typed as follows:

```
frend "AFC.td" <flow_name>
```

## Flow configuration

Flows are defined in flowlist files (by analogy with "playlists"). A flow and its subparts describe which audio files will be played and various parameters of how they will be played.

A flow can be thought of as an object made up of smaller objects. To define a flow is to define all the required objects in its structure.

An object definition is a list of parameters, relevant to the object's type. Some parameters are necessary for all types of objects. These parameters are: the object's name and the class of the object. A definition of one object looks like this:

```
<object_name> : {
class: <class_name>,
<parameter1> : <value1>,
<parameter2> : <value2>,
...
}
```

Parameter _names_ are written without quotes like follows:

```
volume: 1
```

Parameter _values_ can be of three types: _number_, _string_, and _list_.

_String_ values are enclosed in quotes:

```
rootDir: "C:\\Audio"
```

A _list_ is a comma separated sequence of values enclosed in square brackets:

```
streams: ["Rock", "Pop", "Jazz"]
```

Below is the list of classes, whose objects should be defined to create a flow. Parameters with default values are optional: if the parameter is not defined, the default value will be used. Default values are indicated "(_default_: `<value>`)" Parameters without default values are necessary and marked "(_required_)".

### Class "Flow"

A top class representing the whole flow.

Parameters:

**streams**: (_required_) a list of names of Stream objects, which compose the flow. The Stream objects must be defined in the same file. The number of streams can be from 1 to 10. Example:

```
streams: ["Speech", "Music"]
```

Streams are played in a round-robin fashion, e.g. streams A, B and C will be played in the following sequence: `A_B_C_A_B_C_A_B_C...`. Each stream is played until its end, and restarts or not depending on the stream's `loop` parameter. 

One playing iteration through all the streams is called a _cycle_. Streams can skip cycles. Streams have the `freq` (frequency) parameter that defines how frequent they are played in the flow. The `freq`'s value "1" means that the stream will be played in every cycle, "2" - in every second cycle, etc. For example, if a flow is composed of a stream A with frequency "1", and a stream B with frequency "2", it will be played like this:

```
A A B A A B A A B ...
```

**delays**: (_default_: `[0]`) a list of times (in seconds) defining how long should be the silence between playing streams. The number of delays must be the same as the number of streams. Each delay ѕpecifies the pause between the stream with the same index in the list and the next one.


Example of a flow object:

```
"reading" : {
  class: "Flow",
  streams: ["Audiobook", "Ambient"],
  delays: [0, 30]
}
```
In this flow, the "Ambient" stream will be played immediately after the "Audiobook", and the next fragment of "Audiobook" will start in 30 seconds after the "Ambient" fragment has ended.

### Class "Stream"

A class representing a playing sequence. A stream object has an audio file name (or a file name pattern for several files), a definition of a fragment, and it plays the files by fragments in succession. A flow can be composed of more than one stream, in which case the flow will cycle through the streams playing one fragment of each stream at a time. Streams can be configured to skip cycles, thus creating more complex patterns of playing sequence.

Parameters:

**rootDir**: (_required_) The directory relative to which the audio file names are specified. For example if this parameter is `C:/Music` and the audio file name is `song.ogg`, then a file with the full path `C:/Music/song.ogg` will be searched for.

**filePatt**: (_default_: `.*`) A regular expression defining the names of files under the root directory that will be included in the stream. The default value of this parameter will include into the stream all files in all subdirectories under the root directory.

Examples:

`"Nineth symphony.mp3"` - includes a single file;<br>
`"Jane Austine/Emma/.*"` - includes all files in a subdirectory;<br>
`"Classic/.*Adagio.*"` - includes files with "Adagio" in names from a "Classic" subdirectory.<br>

**fragment**: (_required_) the name of a Fragment object describing the way in which the playback of audio files should be fragmented. The Fragment object should be defined in the same flowlist file.

**startPos**: (_default_: `0`) The time position (in seconds) from which the playback of each file in the stream will start.
_Possible values_: non-negative integers (N >= 0).

**freq**: (_default_: `1`) A number specifying how frequently the stream will appear in the flow. The flow playbacks streams in the successive order by iterating over them in cycles.The value "1" of this parameter means that the stream will be played in each cycle of the flow, the value "2" will cause the stream to be only played in every second cycle, etc.
_Possible values_: non-negative integers (N >= 0).

**loop**: (_default_: `0`) A boolean value determining whether or not the stream will be restarted when it reaches the end.
_Possible values_: 0, 1.

An example of a stream object definition:

```
"Spanish" : {
  rootDir: "D:/Podcasts/Learning Spanish",
  filePatt: ".*\.mp3",
  startPos: 60,
  fragment: "podcasts",
  freq: 1,
  loop: 0
}
```
