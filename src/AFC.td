/*
Audio Flow Combiner
---------------------

MIT License

Copyright (c) 2021-2022 Albert Berger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--------------------

Github:        https://github.com/al-berger/AFC
Version:       0.51 (works with TREE3 v0.2-504 and higher)
Last edited:   Mon, 19 Sep 2022 10:12
*/

#lang transd

Require : { searchDirs: ["."], packages: ["config", "utils"] }

class Play: {
  import: "Utils",
  import: "Config::soxPath",
  volume: Double(0.5),
  tempo: Double(1.0),
  fadeIn: Double(0.0),
  fadeOut: Double(0.0),

  init: (λ objs Index<String Vector<Object>>()
  ),

  play: (λ yfileName String() startPos Double() thr_done Bool() 
            length Double()
    (log-debug "Play " name " started playing ")
    (with cmd String( soxPath " -q \"" yfileName
            "\" -d trim " startPos " " length " tempo " tempo 
            " fade t " fadeIn " -0 " fadeOut " vol " volume)
        (log-debug "cmd: " cmd)
        (start-process cmd thr_done)
    )
  )
}

class Fragment: {
  import: "Utils",
  length: Double(0.0),
  pause: Double(0.0),
  plays: Vector<String>(),

  playObjs: Vector<Play>(),

  init: (λ objs Index<String Vector<Object>>()
    (for plname in plays do
        (append playObjs Play())
        (load-from-object (back playObjs) (get (get objs plname) 0))
    )
    (*= pause 1000.0)
  ),

  play: (λ fileName String() startPos Double() thr_done Bool()
    (log-debug "Fragment " name " started playing ")
    (for pl in playObjs do 
        (play pl fileName startPos thr_done length)
        (while (not thr_done)
           (sleep 1000))
        (if (< @idx (- (size playObjs) 1))
            (log-debug String("Fragment: " name " sleeping between plays: " pause ))
            (sleep pause)
            (= thr_done false)
        )
    )
    (+= startPos length)
  )
}

class Stream: {
  import: "Utils",
  rootDir: String(),
  filePatt: String(),
  startPos: Double(0.0),
  fragment: String(),
  freq: Int(1),
  loop: Int(0),
  fragGap: Double(0.0),

  files: Vector<String>(),
  curFile: String(),
  curFileIdx: Int(0),
  curFileLen: Double(-1.0),
  curPos: Double(0.0),
  freqCnt: 0,
  fragObj: Fragment(),
  finished: false,
  skipped: false,

    access allow: { finished: [Flow], name: [Flow], skipped: [Flow] },

  init: (λ objs Index<String Vector<Object>>()
    (with dir Directory() 
        (read-rec dir rootDir filePatt)
        (= files (files dir)))
    (if (size files) 
        (= curFile (get files 0))
        (load-from-object fragObj (get (get objs fragment) 0))
        (init fragObj objs)
        (log-info String("Stream " name ": file list:" files))
    else
        (log-debug "Stream " name " doesn't have any files")
    )
  ),

  play: (λ thr_done Bool()
    (log-debug "Stream " name " started playing ")
    (log-debug "   curPos: " String( curPos "; curFileLen: " curFileLen ))
    (if (> curPos curFileLen) 
        (log-debug "   curPos > curFileLen: " 
            String( curPos "; " curFileLen "; curFileIdx: " curFileIdx ))
        (if (< curFileIdx (size files) )
            (= curFile (get files curFileIdx))
            (log-info String("Stream " name ": current file: " curFile ))
            (+= curFileIdx 1)
            (= curFileLen -1.0)
        else (= curFileLen 0.0)
            (= curFile "")
            (= curPos 0.0)
    ))
    (if (not curFile)
        (log-info "The stream " name " has finished")
        (= finished true) (= thr_done true) (ret)
    )
    (+= freqCnt 1)

        (if (< curFileLen 0.0)
            (= curFileLen (get-file-len curFile))
            (= curPos startPos)
        else (if (> fragGap 0.0) (+= curPos fragGap)
              else (if (> curPos (abs fragGap)) (+= curPos fragGap)))
        )

    (if (not (mod freqCnt freq))

        (log-debug "   curFile: " curFile String( "; curPos: " curPos ))
        (play fragObj curFile curPos thr_done)
        (= skipped false)
    else 
        (set thr_done true)
        (= skipped true)
        (log-info String("Stream " name ": play count: " freqCnt " - skipping"))
    )
  )
}

class Flow: {
import: "Utils",
import: "Stream",
  streams: Vector<String>(),
  async: Bool(false),
  delays: Vector<Double>(),

  thr_done: Bool( false ),
  streamObjs: Vector<Stream>(),

  init: (λ objs Index<String Vector<Object>>()
    (for streamName in streams do
        (append streamObjs Stream())
        (load-from-object (back streamObjs) 
                (get (get objs streamName) 0))
        (init (back streamObjs) objs)
    )
  ),

  play: (λ 
    active Bool(true)
    (log-debug "flow started")
    (while active
        (= active false)
        (for st in streamObjs do 
            (log-debug "flow: starting next stream: " st.name)
            (if (not st.finished)
                (= active true)
                (= thr_done false)
                (play st thr_done)
                (while (not thr_done)
                    (sleep 1000))
                (log-debug "flow: THR_DONE is SET")
                (if (not st.skipped)
                    (log-debug String( "flow: began pause: " (get delays @idx)) )
                    (sleep (* (get delays @idx) 1000.0)))
            )
            (log-debug "flow: stream's cycle ended " st.name)
        )
    )
    (log-info "Flow: " name " has no active streams. Exiting.")
  )
}

MainModule: {
import: "Config",
import: "Utils",

// the flow object
flowObj: Flow(),

// objects from the user flowlist
objs: Index<String Vector<Object>>(),

flowName: "",

_start: (λ 
    (log-debug "AFC started")

//-- process command line arguments

    (if (== @numArgs 1) (set flowName defaultFlow)
    elsif (== @numArgs 2) (set FLfile (get @progArgs 0))
    else (with ind (progargs-to-index @progArgs)  
            (log-info "arguments: " String(ind))
            (= FLfile (get-val ind "FLfile" FLfile))
            (= flowName (get-val ind "flow" defaultFlow))
    ))

    (log-info String("FLfile: " FLfile "; flow: " flowName))

// -- read the flowlist definition objects from the flowlist file

    (rebind objs (group-by 
                (read-tsd-file FLfile) 
                (λ ob Object() -> String() 
                    (get-String ob "name"))))

// -- create the root of hierarchy - the flow object

    (load-from-object flowObj (get (get objs flowName) 0))

// -- init the flow object

    (init flowObj objs)

// -- start flow

    (play flowObj)
)
}
