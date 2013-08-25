module champollion

struct grammar = {
	  whiteSpaces
	, feeds
	, letters
	, decimalDigits
	, operators
	, characters
	, allowedStartIdentifiers
	, stringDelimiter
	, remarkDelimiter
	, keyWords
}

# Class Token
# 	properties
struct token = {type, value, line}
# 	methods
augment champollion.types.token { }
# 	constructor
function Token = |type, value, line| -> token():type(type):value(value):line(line)

# Class Index
# 	properties
struct index = {value, isEOF, isEnd} #isEnd is used by the parser
# 	methods
augment champollion.types.index {
	function skip = |this| -> this:value(this:value()+1)
}
# 	constructor
function Index = -> index():value(0):isEOF(false):isEnd(false)

# ===== LEXER =====

# Class Lexer
# 	properties
struct lexer = {tokens, line, src, grammarDef, index, strStart, remStart}
# 	methods
augment champollion.types.lexer {
	function source = |this, src| {
		this:src(src:split("")) # transform to an array of char # implicit return this, because of structure
		#println("SRC : \n" + this:src():toString())
		return this
	}

	function grammar = |this, grammar| -> this:grammarDef(grammar) # implicit return this, because of structure

	# get the next character and advance
	function nextChar = |this| {
		var ch = null
		if this:index():value() < this:src():length() {
			ch = this:src():get(this:index():value())
			this:index():skip()
		} else {
			this:index():isEOF(true)
		}
		
		return ch
	}

	# get the next character without advancing
	function peekNextChar = |this| {
		if this:index():value() < this:src():length() {
			return this:src():get(this:index():value())
		} else { return "\\x00" }	# to be verified
	}

	# helper
	function createToken = |this, type, value| {
        return Token(type, value, this:line())
    }

	# Define the types of the tokens
    function isWhiteSpace = |this, ch| {
        return(ch:equals(" ") or this:grammarDef():whiteSpaces():indexOf(ch) >= 0) 
    }
    function isLetter = |this, ch| {
        return (this:grammarDef():letters():indexOf(ch) >= 0)
    }
    function isOperator = |this, ch| {
        return (this:grammarDef():operators():indexOf(ch) >= 0)
    }
    function isCharacter = |this, ch| {
        return (this:grammarDef():characters():indexOf(ch) >= 0)
    }
    function isAllowedStartIdentifier = |this, ch| {
        return (this:grammarDef():allowedStartIdentifiers():indexOf(ch) >=0)
    }
    function isStringDelimiter = |this, ch| {
        return (this:grammarDef():stringDelimiter():indexOf(ch) >= 0)
    }
    function isRemarkDelimiter = |this, ch| {
        return (this:grammarDef():remarkDelimiter():indexOf(ch) >= 0)
    }
    function isDecimalDigit = |this, ch| {
        return (this:grammarDef():decimalDigits():indexOf(ch) >= 0)
    }
    function isFeed = |this, ch| {
        return (this:grammarDef():feeds():indexOf(ch) >= 0)
    }

    # if "identifier/word" check if keyword
    function isKeyWord = |this, identifier| {

        let whatIsIt = this:grammarDef():keyWords():
        		filter(|record|-> record == identifier)
        if whatIsIt:size() > 0 { 
            return "Keyword" 
        } else { 
            return "Identifier" 
        }
    }

    # White Spaces
    #    ignore white spaces and continue move forward until there is no such white space anymore

    function skipSpaces = |this| {
        var ch = null
        while this:index():value() < this:src():length() {

            ch = this:peekNextChar()
            if not this:isWhiteSpace(ch) {
                break
            }
            #new line
            if this:isFeed(ch) is true {
                 this:line(this:line()+1) 
             }
            this:nextChar()
        }
    }

    # operators :
    #    they are defined with grammar object
    
    function scanOperator = |this| {
        let ch = this:peekNextChar()
        if this:isOperator(ch) {
            return this:createToken("Operator", this:nextChar())
        } else {
        	return null	
        }   
    }

    # Deciding whether a series of characters is an identifier
    # we allow the first character to be a letter, a character allowed for start identifier,

    function isIdentifierStart = |this, ch| {
        return this:isAllowedStartIdentifier(ch) or this:isLetter(ch)
    }

    function isIdentifierPart = |this, ch| {
        return this:isIdentifierStart(ch) or this:isDecimalDigit(ch)
    }

    function scanIdentifier = |this| { # scanIdentifierOrKeyWord
        var ch = null
        var id = null

        ch = this:peekNextChar()
        if not this:isIdentifierStart(ch) {
            return null
        }

        id = this:nextChar()
        while (true) {
            ch = this:peekNextChar()
            
            if not this:isIdentifierPart(ch) {
                break
            }
            id = id + this:nextChar()
        }

        return this:createToken(this:isKeyWord(id), id)
    }

    function scanNumber = |this| {
        var ch = null 
        var number = null

        ch = this:peekNextChar()

        if (not this:isDecimalDigit(ch)) and (not ch:equals(".")) {
            return null
        }

        number = ""
        if not ch:equals(".") {
            number = this:nextChar()
            while (true) {
                ch = this:peekNextChar()
                if not this:isDecimalDigit(ch) {
                    break
                }
                number = number + this:nextChar()
            }
        }

        if ch:equals(".") {
            number = number + this:nextChar()
            while (true) {
                ch = this:peekNextChar()
                if not this:isDecimalDigit(ch) {
                    break
                }
                number = number + this:nextChar()
            }
        }
        return this:createToken("Number", number)
    }

    function isStringStart = |this, ch| {
        if this:isStringDelimiter(ch) {
        	if ((this:strStart() is false) or (this:strStart() is null)) {
        		this:strStart(true)
        	} else {
        		this:strStart(false)
        	}
            return this:strStart()

        } else { return false }

    }

    function isStringEnd = |this, ch| { # mouais bof, à vérifier
        if this:isStringDelimiter(ch) {
        	if this:strStart() is true {
        		this:strStart(false)
                return true
        	} else {
        		this:strStart(true)
                return false
        	}
        	#return (not this:strStart())
        } else { return false }
    }

    function isStringPart = |this, ch| { # almost same thing as isIdentifierPart
        return this:isStringEnd(ch)
            or this:isStringStart(ch)
            or this:isAllowedStartIdentifier(ch)
            or this:isLetter(ch)
            or this:isCharacter(ch)
            or this:isRemarkDelimiter(ch)
            or this:isDecimalDigit(ch)
            or this:isWhiteSpace(ch)
            or this:isOperator(ch)

            #or this:isFeed(ch)

    }

    function scanString = |this| {
        var ch = null
        var id = null

        ch = this:peekNextChar()

        if ((not this:isStringStart(ch)) or (not this:isStringEnd(ch))) {
            return null
        } else {
	        this:nextChar() # not keep first '"' 
	        id = this:nextChar()

	        while (true) {
	            ch = this:peekNextChar()
	            
                if not this:isStringPart(ch) {
                    this:nextChar() # skip last '"'
                    break
                }                    
	            id = id + this:nextChar()
	        }
	        return this:createToken("String", id)        	
        }


    }    

    function isRemarkStart = |this, ch| {

        if this:isRemarkDelimiter(ch) {

        	if (this:remStart() is false) or (this:remStart() is null) {
        		this:remStart(true)
        	} else {
        		this:remStart(false)
        	}
            return this:remStart()

        } else { return false }

    }

    function isRemarkEnd = |this, ch| { # mouais bof, à vérifier
        if this:isRemarkDelimiter(ch) {
        	if this:remStart() is true {
        		this:remStart(false)
        	} else {
        		this:remStart(true)
        	}
        	return not this:remStart()
        } else { return false }
    }

    function isRemarkPart = |this, ch| { # same thing as isIdentifierPart
        return this:isRemarkEnd(ch)
            or this:isRemarkStart(ch)
            or this:isAllowedStartIdentifier(ch)
            or this:isLetter(ch)
            or this:isCharacter(ch)
            or this:isStringDelimiter(ch)
            or this:isDecimalDigit(ch)
            or this:isWhiteSpace(ch)
            or this:isOperator(ch)
    }

    function scanRemark = |this| {

        var ch = null
        var id = null

        ch = this:peekNextChar()

        if (not this:isRemarkStart(ch)) or (not this:isRemarkEnd(ch)) {
            return null
        } else {

	        this:nextChar() # skip first '#' 
	        id = this:nextChar()

	        while (true) {
	            ch = this:peekNextChar()
	            if not this:isRemarkPart(ch) {
	                this:nextChar() # skip last '#'
	                break
	            }
	            id = id + this:nextChar()
	        }
	        return this:createToken("Remark", id)        	
        }
    }        

    function next = |this| {
        var token = null

        this:skipSpaces()
        
        if this:index():value() >= this:src():length() {
            this:index():isEOF(true)
            return null
        }

        token = this:scanRemark()
        if token isnt null {
            return token
        }

        token = this:scanString()
        if token isnt null {
            return token
        }

        token = this:scanOperator()
        if token isnt null {
            return token
        }

        token = this:scanNumber()
        if token isnt null {
            return token
        }

        token = this:scanIdentifier()
        if token isnt null {
            return token
        }

        if token is null {
            return this:createToken("Unknown", this:nextChar())
        } else {
        	return null	
        }
        #throw 'Unknown token from character ' + this.peekNextChar()
    }

    function tokenize = |this| {
        
        while this:index():isEOF() is false {
            var tok = this:next()
                        
            if tok isnt null {
            	if not tok:type():equals("Unknown") {
            		#tok:line(this:line())
            		this:tokens():add(tok)	
            	}
            } 
        }
        return this
    }

    #function each = |this, callbk| {
    #    
    #    this:tokens():each(|token|{
    #        callbk(token, this:tokens():indexOf(token))
    #    })
    #    return this
    #}

    #L:each(|el|->println(el+" "+L:indexOf(el)))

}
# 	constructor
function Lexer = {
	let self = lexer():tokens(list[]):line(0):index(Index())

	return self
}


# ===== GENERIC PARSER =====

struct parser = {
	index,
	tokensList,
	currentToken
}
augment champollion.types.parser { 

	function tokens = |this, toks| {
		this:tokensList(toks)
        return this
	}

	function peekNextToken = |this| {
		var tok = null
		if this:index():value() < this:tokensList():size() {
			tok = this:tokensList():get(this:index():value())
		}
		return tok
	}
    # override (useful?)
    function peekNextToken = |this, pos| {
        var tok = null
        if (this:index():value()+pos) < this:tokensList():size() {
            tok = this:tokensList():get(this:index():value()+pos)
        }
        return tok
    }


    function peekPreviousToken = |this| {
        return this:tokensList():get(this:index():value() - 1)
    }

    function nextToken = |this| {
        var tok = null
        if this:index():value() < this:tokensList():size() {
            tok = this:tokensList():get(this:index():value())
            this:index():skip()
        } else {
            this:index():isEnd(true)
        }
        this:currentToken(tok)
        return tok
    }    

    function isKeyWord = |this, token| {
        return token:type():equals("Keyword")
    }
    function isIdentifier = |this, token| {
        return token:type():equals("Identifier")
    }

    # this is an example
    function isClass = |this, token| {
        return (this:isKeyWord(token) and token:value():equals("class"))
    }

    function isBlockStart = |this, token| {
        return (token:type():equals("Operator")  and token:value():equals("{"))
    }
    function isBlockEnd = |this, token| {
        return (token:type():equals("Operator") and token:value():equals("}"))
    }

    function isBracketStart = |this, token| {
        return (token:type():equals("Operator")  and token:value():equals("["))
    }
    function isBracketEnd = |this, token| {
        return (token:type():equals("Operator") and token:value():equals("]"))
    }

}

# constructor
function Parser = {
	let self = parser():index(Index())
	return self
}

function Grammar = -> grammar()
    :whiteSpaces("\\u0009\\u00A0\\u000A\\u0020\\u000D")     # tabulation, [no break space], [line feed], [space], [carriage feed] */
    :feeds("\\u000A\\u000D")
    :letters("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.!§%€")
    :decimalDigits("0123456789")
    :operators("+-*/(){}[]=.")  # . as operator if this.something for example
    :characters(":;,'.")
    :allowedStartIdentifiers("_$")
    :stringDelimiter("\"")
    :remarkDelimiter("#")
    :keyWords(["class"])
