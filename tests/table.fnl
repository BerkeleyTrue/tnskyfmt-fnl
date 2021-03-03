(local t {:a "and then she knew with an instinctive mammalian certainty"
          :b [2 3 4 "(" 4]
          :b.5 1.5})

{:this :table
 ;; has a comment right before
 :a key}

{:this :table
 :has ;; a comment right before
 "a value"}

{:this :table
 ;; has a comment at the end
 }

{:another key : kv3 : and-one-more}

(global themes {:stone {:0 96
                        :1 greystone
                        :0->1 112
                        :2 144
                        :0->2 176
                        :1->2 160}
                :bright {:0 97
                         :1 greystone
                         :0->1 113
                         :2 145
                         :0->2 177
                         :1->2 161}
                :woods {:0 [98 99 100]
                        :1 greystone
                        :0->1 114
                        :2 146
                        :0->2 178
                        :1->2 162}})
