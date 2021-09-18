#lang transd

Require : { searchDirs: ["."], packages: ["config"] }


public module Utils: 
{
    import: "Config::soxPath",

    get-file-len: (λ fname String()
        (with //cmd String("sox \"" curFile "\" -n stat 2>&1")
            cmd String( soxPath " \"" fname 
                    "\" -d trim 0.00 0.1 vol 0.0 2>&1" )
            outp String() _done Bool(false) ret 0.0
            (lout "get-file-len: " cmd)
            (start-process cmd _done outp)
            (while (not _done)
                (sleep 1000))
            //(= slen (substr outp after: "):" before: "\nScaled"))
            (= outp (substr outp from: after: "Duration: " to: "."))
            (with v (split outp ":")
                (+= ret (* 60 Int((get v 0))) 
                        (* 60 Int((get v 1)))
                        Int((get v 2)))
            )
(lout "len: " ret)
            (ret ret)
    ))
}
