/*
Audio Flow Combiner
--------------------
Project website: https://github.com/al-berger/AFC
*/
#lang transd

Require : { searchDirs: ["."], packages: ["config"] }


public module Utils: 
{
    import: "Config::soxPath",
    import: "Config::verbosity",

    log-info: (λ s1 String() s2 String() s3 String()
        (if (>= verbosity 2) (lout s1 s2 s3))
    ),

    log-debug: (λ s1 String() s2 String() s3 String()
        (if (>= verbosity 3) (lout s1 s2 s3))
    ),

    get-file-len: (λ fname String()
        (with //cmd String("sox \"" curFile "\" -n stat 2>&1")
            cmd String( soxPath " \"" fname 
                    "\" -d trim 0.00 0.1 vol 0.0 2>&1" )
            outp String() _done Bool(false) ret 0.0
    (lout "get-file-len: RET: " ret "; outp: " outp)
            (start-process cmd _done outp)
            (while (not _done)
                (sleep 1000))
            //(= slen (substr outp after: "):" before: "\nScaled"))
            (= outp (substr outp from: after: "Duration: " to: "."))
            (log-debug "get-file-len: " outp)
            (with v (split outp ":")
    (lout "get-file-len: v: " v)
                (+= ret (* 3600 Int((get v 0))) 
                        (* 60 Int((get v 1)))
                        Int((get v 2)))
            )
            (log-debug String( "len: " ret ))
            (ret ret)
    ))
}
