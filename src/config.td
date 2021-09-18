#lang transd



public module Config: 
{
    soxPath: "sox",
    defaultFlow: "flow1",

    FLfile: String(),

    @init: (λ 
        (if (not FLfile)
            (with rootdir (substr @sourceFile from: 0 to: after: last: "/")
                _s (if (eq @OS_Type "Windows") "flowlist.tsd" 
                    else "flowlistl.tsd")
                (= FLfile (+ rootdir _s))
        ))
    )
}
