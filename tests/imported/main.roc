## An app that imports a type module beside it: roc-types must write the
## imported module's types as well as the app's.
app [main] { pf: platform "../nested/pf/main.roc" }

import Greeting

main : Str
main = Greeting.hello("roc")
