/*
Audio Flow Combiner
--------------------

This is the AFC configuration file.

Flowlists are not defined here. A flowlist should be defined in a separate
file and its full path specified in the "FLfile" parameter below.
*/
#lang transd



public module Config: 
{
    // -- Begin of the editable part of the Config module -- //
    // ........................................................

    // SoX command (may need the full path).
    soxPath: "sox",

    // The default flow name.
    defaultFlow: "flow1",

    // Flowlist file name. 
    FLfile: "",

    // Three levels of verbosity: error=1, info=2, debug=3
    verbosity: 1,

    // -- End of the editable part of the Config module -- //
    // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    @init: (λ 
        (if (not FLfile)
            (with rootdir (substr @sourceFile from: 0 to: after: last: "/")
                _s (if (eq @OS_Type "Windows") "../flowlists/flowlist.tsd" 
                    else "../flowlists/flowlistl.tsd")
                (= FLfile (+ rootdir _s))
        ))
    )
}
