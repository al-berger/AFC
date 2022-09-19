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

    log-info: (λ const s1 String() const s2 String() const s3 String()
        (if (>= verbosity 2) (lout s1 s2 s3))
    ),

    log-debug: (λ const s1 String() const s2 String() const s3 String()
        (if (>= verbosity 3) (lout s1 s2 s3))
    ),

    get-file-len: (λ fname String()
        (with //cmd String("sox \"" curFile "\" -n stat 2>&1")
            cmd String( soxPath " \"" fname 
                    "\" -d trim 0.00 0.1 vol 0.0 2>&1" )
            outp String() _done Bool(false) ret 0.0
            (start-process cmd _done outp)
            (while (not _done)
                (sleep 1000))
            //(= slen (substr outp after: "):" before: "\nScaled"))
            (= outp (substr outp from: after: "Duration: " to: "."))
            (log-debug "get-file-len: " outp)
            (with v (split outp ":")
                (+= ret (* 3600 Int((get v 0)))
                        (* 60 Int((get v 1)))
                        Int((get v 2)))
            )
            (log-debug String( "len: " ret ))
            (ret ret)
    )),
    
    progargs-to-index: (λ args Vector<String>()
        (with key "" ret Index<String String>()
        (for s in Range(in: args 1 -0) do
            (if (starts-with s "-")
                (= key (sub s 1)) (insert ret (cp key) "") 
            elsif (size key)
                (set-el ret key s)
            else (ret ret)
            ))
        (ret ret)
    ))
}
