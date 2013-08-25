#Champollion

Champollion is a generic **lexer** (tokenizer), with a little **parser**, largely inspired by these blog posts [math evaluator in javascript: part 1 (the tokenizer)](http://ariya.ofilabs.com/2011/08/math-evaluator-in-javascript-part1.html) and [math expression evaluator in javascript: part 2 (parser)](http://ariya.ofilabs.com/2011/08/math-evaluator-in-javascript-part-2.html) by **Ariya Hidayat**.

Champollion is very simple, written in **[Golo](http://golo-lang.org/)** and you can use it for your own needs (json parsing, documentation generator, ...)

Thanks to Champollion, i've been able to write a json parser **[Bozzo](https://github.com/k33g/bozzo)**

##How to (silly sample)

See `simple.golo`. To run it : `golo golo --files champollion.golo simple.golo`

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

###Write some "code"

```coffeescript
let sourceCode = """

	# this is a remark #
	# say hello        #

	say "Hello World!"

	$AZERTY 12
	$QWERTY 10
	
	read $AZERTY
	read $QWERTY

	say "That's all folks!"
	
"""
```

###Tokenize the code

```coffeescript
# Tokenize source code (with generic grammar of Champollion)
let lexer = Lexer():grammar(MySimpleGrammar()):source(sourceCode):tokenize()

# Display tokens
lexer:tokens():each(|token| {
	println(
		"Type : %s, Value : %s":format(
			token:type():toString(),token:value():toString()
		)
	)
})
```

*output :*

	Type : Remark, Value :  this is a remark
	Type : Remark, Value :  say hello
	Type : Keyword, Value : say
	Type : String, Value : Hello World!
	Type : Identifier, Value : $AZERTY
	Type : Number, Value : 12
	Type : Identifier, Value : $QWERTY
	Type : Number, Value : 10
	Type : Keyword, Value : read
	Type : Identifier, Value : $AZERTY
	Type : Keyword, Value : read
	Type : Identifier, Value : $QWERTY
	Type : Keyword, Value : say
	Type : String, Value : That's all folks!

###Parse the code

```coffeescript
# set tokens for the parser
let parser = Parser():tokens(lexer:tokens())

# Interpreter
let variables = map[]

while not parser:index():isEnd() {

    let token = parser:nextToken()

    if token isnt null {
    	# hello = System.out.println
    	if parser:isKeyWord(token) and token:value():equals("say") {
    		if parser:peekNextToken() isnt null {
        		let value = parser:peekNextToken():value()
        		println(value)        			
    		}
    	}

    	if parser:peekNextToken() isnt null 
    		and parser:isIdentifier(token) 
    		and parser:peekNextToken():type():equals("Number") 
    	{
    		let value = parser:peekNextToken():value()
    		variables:put(token:value(), value) 
    		println(variables)
    	}

    	if parser:isKeyWord(token) and token:value():equals("read")  {
    		if parser:peekNextToken() isnt null {
        		let value = parser:peekNextToken():value()
        		println(variables:get(value))
        	}
    	}
      
    }

} # end while    
```

*output :*

	Hello World!
	{$AZERTY=12}
	{$AZERTY=12, $QWERTY=10}
	12
	10

That's all
