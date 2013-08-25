module simple

import champollion

# Make your own grammar
function MySimpleGrammar = -> grammar()
    :whiteSpaces("\\u0009\\u00A0\\u000A\\u0020\\u000D")     # tabulation, [no break space], [line feed], [space], [carriage feed] */
    :feeds("\\u000A\\u000D")
    :letters("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.!§%€")
    :decimalDigits("0123456789")
    :operators("+-*/(){}[]=.")  # . as operator if this.something for example
    :characters(":;,'.")
    :allowedStartIdentifiers("_$")
    :stringDelimiter("\"")
    :remarkDelimiter("#")
    :keyWords(["say", "read"])


function main = |args| {

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

}