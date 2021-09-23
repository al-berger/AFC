/* 
 * Audio Flow Combiner
 * ---------------------
 * Author: Albert Berger [/com/gmail/alberger]
 * Github: https://github.com/al-berger/AFC
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

  play: (λ fileName String() startPos Double() thr_done Bool() 
            length Double()
    (log-debug "Play " name " started playing ")
    (with cmd String( soxPath " -q \"" fileName
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
  fragGap: Double(0.0),
  plays: Vector<String>(),

  playObjs: Vector<Play>(),

  init: (λ objs Index<String Vector<Object>>()
    (for plname in plays do
        (append playObjs Play())
        (load-from-object (back playObjs) (get (snd (get objs plname)) 0))
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
//;w(lout "sleep between fragments: " pause " sec")
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

  files: Vector<String>(),
  curFile: String(),
  curFileIdx: Int(-1),
  curFileLen: Double(-1.0),
  fragObj: Fragment(),
  finished: false,

    access allow: { finished: [Flow], name: [Flow] },

  init: (λ objs Index<String Vector<Object>>()
    (with dir Directory() 
        (read-rec dir rootDir filePatt)
        (= files (files dir)))
    (if (size files) 
        (= curFile (get files 0))
        (load-from-object fragObj (get (snd (get objs fragment)) 0))
        (init fragObj objs)
        (log-debug "Stream files: " name String(files))
    else
        (log-debug "Stream " name " doesn't have any files")
    )
  ),

  play: (λ thr_done Bool()
    (log-debug "Stream " name " started playing ")
    (if (> startPos curFileLen) 
        (if (< curFileIdx (- (size files) 1))
            (= curFile (get files curFileIdx))
            (+= curFileIdx 1)
            (= curFileLen -1.0)
        else (= curFileLen 0.0)
            (= curFile "")
            (= startPos 0.0)
    ))
    (if (not curFile)
        (log-debug name " finished")
        (= finished true) (= thr_done true) (ret)
    )
    (if (< curFileLen 0.0)
        (= curFileLen (get-file-len curFile))
        (= startPos 0.0)
    )
    (play fragObj curFile startPos thr_done)
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
                (get (snd (get objs streamName)) 0))
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
                    (sleep (get delays @idx))
            )
(log-debug "flow: stream's cycle ended " st.name)
        )
    )
(log-debug "flow: no active streams. Exiting.")
  )
}

MainModule: {
import: "Config",
import: "Utils",

flowObj: Flow(),
objs: Index<String Vector<Object>>(),
flowName: "",

_start: (λ fname String() cmd String()
(log-debug "prog started")
    (if (> @numArgs 1) (set flowName (get @progArgs 0))
    else (set flowName defaultFlow))
    (rebind objs (group-by 
                (read-tsd-file FLfile) 
                (λ ob Object() -> String() 
                    (get-String ob "name"))))
    (load-from-object flowObj (get (snd (get objs flowName)) 0))
    (init flowObj objs)
    (play flowObj)
)

}
