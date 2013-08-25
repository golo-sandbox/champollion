#Champollion

Champollion is a generic **lexer** (tokenizer), with a little **parser**, largely inspired by these blog posts [math evaluator in javascript: part 1 (the tokenizer)](http://ariya.ofilabs.com/2011/08/math-evaluator-in-javascript-part1.html) and [math expression evaluator in javascript: part 2 (parser)](http://ariya.ofilabs.com/2011/08/math-evaluator-in-javascript-part-2.html) by ** Ariya Hidayat**.

Champollion is very simple, written in **[Golo](http://golo-lang.org/)** and you can use it for your own needs (json parsing, documentation generator, ...)

##How to

###First, define a Grammar

```coffeescript
function MySimpleGrammar = -> grammar()
    :whiteSpaces("\\u0009\\u00A0\\u000A\\u0020\\u000D")
    :feeds("\\u000A\\u000D")
    :letters("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.!§%€")
    :decimalDigits("0123456789")
    :operators("+-*/(){}[]=.")  # . as operator if this.something for example
    :characters(":;,'.")
    :allowedStartIdentifiers("_$")
    :stringDelimiter("\"")
    :remarkDelimiter("#")
    :keyWords(["say", "read"])

```

