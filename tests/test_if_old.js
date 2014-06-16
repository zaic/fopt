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
"init_arr" : {
        "type" : "extern",
        "code" : "some_function_name",
        "args" : [{"type": "name"}]
}
,
"init_random_value" : {
        "type" : "extern",
        "code" : "init_random_value",
        "args" : [{"type": "int"}, {"type": "name"}]
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
                    "type": "for",
                    "var": "i",
                    "first" : {"type": "iconst", "value": "0"},
                    "last" : {"type": "iconst", "value": "1-1"},
                    "body": [
                        {
                            "type": "dfs",
                            "names": []
                        },
                        {
                            "type": "exec",
                            "id": ["init_random_value"],
                            "code": "init_random_value",
                            "args": [{"type": "iconst", "value": "12"}, {"type": "id", "ref": ["N", {"type": "id", "ref": ["i"]}]}],
                            "rules": []
                        }
                    ]
                }
,
                 {
                            "type" : "if",
                            "cond" : {"type":">","operands":[{"type":"id","ref":["N", {"type": "id", "ref": ["k"]}]},
                                                             {"type": "iconst", "value": "1"}]},
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