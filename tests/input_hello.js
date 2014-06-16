{
"hello_world" : {
        "type" : "extern",
        "code" : "c_helloworld",
        "args" : []
}
,
"init_n" : {
        "type" : "extern",
        "code" : "some_function_name",
        "args" : [{"type": "name"}]
}
,
"main" : {
        "type" : "struct",
        "args" : [],
        "body" : [
                {
                        "type" : "dfs",
                        "names" : ["N", "k"]
                }
,               {
                        "type" : "exec",
                        "id" : ["a"],
                        "code" : "hello_world",
                        "args" : []
                }
,               {
                        "type" : "exec",
                        "id" : ["b"],
                        "code" : "init_n",
                        "args" : [{"type": "id", "ref": ["N"]}]
                }
,
                 {
                            "type" : "if",
                            "cond" : {"type":">","operands":[{"type":"id","ref":["N"]}, {"type": "iconst", "value": "1"}]},
                            "body" : [
                        {
                            "type" : "exec",
                            "id" : ["_l21"],
                            "code" : "hello_world",
                            "args" : [],
                            "rules" : []
                        }
                            ]
                        }

                ]
        }
}