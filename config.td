#lang transd



public module Config: {

    PLFile: String(),
    defaultFlow: "flow1",
    @init: (λ 
        (with rootdir (substr @sourceFile from: 0 to: after: last: "/")
            (= PLFile (+ rootdir "flow.tsd"))
        )
    )
}
