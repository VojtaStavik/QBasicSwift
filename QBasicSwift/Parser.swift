//
//  Parser.swift
//  QBasicSwift
//
//  Created by Stavik, Vojta on 06/01/17.
//  Copyright © 2017 VojtaStavik. All rights reserved.
//

import Foundation

struct QBasicParser {
    // Program is an array of blocks
    func program() -> StringParser<[Block]> {
        return (many(block) <<< eof)()
    }
}

// MARK: - Block & Statements
extension QBasicParser {

    // Each block has its label and statements
    func block() -> StringParser<Block> {
        return (option(Label.main, label) >>- { label_ in
            self.statements >>- {
                create(Block(label: label_,
                             statements: $0.flatMap{$0} ))
            }
        })()
    }
}

// MARK: - Statements
extension QBasicParser {
    
    func statements() -> StringParser<[Statement]> {
        return (many1(statement) >>- {
            create($0.flatMap{$0})
        })()
    }
    
    func statement() -> StringParser<Statement?> {
        return (
            attempt(printCommand)
                <|> attempt(comment)
                <|> attempt(assignment)
                <|> attempt(forLoop)
                <|> attempt(ifStatement)
                <|> attempt(clsCommand)
                <|> attempt(declaration)
                <|> attempt(goto)
                <|> attempt(emptyLine)
            )()
    }
    
    // Empty line or line with only spaces
    func emptyLine() -> StringParser<Statement?> {
        return (spaces >>> endOfLine >>- { _ in create(nil) })()
    }
}

// MARK: - Labels
extension QBasicParser {

    // Line number or label
    func label() -> StringParser<Label> {
        return (attempt(lineNumber) <|> attempt(namedLabel))()
    }
    
    // 10 CLS
    func lineNumber() -> StringParser<Label> {
        return (many1(digit) >>- { digits in
            create(Label(name: String(digits)))
            })()
    }
    
    // sayHi: PRINT "Hi"
    func namedLabel() -> StringParser<Label> {
        return (labelIdentifier <<< char(":") >>- { name in
            create(Label(name: String(name)))
            })()
    }
    
    func labelIdentifier() -> StringParser<String> {
        return (many1(alphaNum) >>- { create(String($0)) })()
    }
}


// MARK: - IF statement
extension QBasicParser {
    
    func ifStatement() -> StringParser<Statement?> {
        return (attempt(ifStatementSimple) <|> attempt(ifStatementFull))()
    }
    
    //IF 5 < 2 THEN
    //  PRINT "5 Is Less Than 2"
    //END IF
    func ifStatementFull() -> StringParser<Statement?> {
        return (spaces >>> Keyword.IF >>> spaces >>> expression <<< spaces <<< Keyword.THEN <<< endOfLine >>- { exp in
            self.statements >>- { ifBlock in
                option([Statement](), attempt(spaces >>> Keyword.ELSE) >>> endOfLine >>> spaces >>> self.statements) >>- { elseBlock in
                    spaces >>> Keyword.ENDIF >>- { _ in
                        create(.if_(expression: exp, block: ifBlock, elseBlock: elseBlock))
                    }
                }
            }
        })()
    }
    
    //IF 5 < 2 THEN PRINT "5 Is Less Than 2"
    func ifStatementSimple() -> StringParser<Statement?> {
        return (spaces >>> Keyword.IF >>> spaces >>> expression <<< spaces <<< Keyword.THEN >>- { exp in
            spaces >>> self.statement <<< spaces <<< endOfLine >>- { com in
                create(Statement.if_(expression: exp, block: [com!], elseBlock: []))
            }
        })()
    }
}


// MARK: - Variables
extension QBasicParser {
    
    // PRINT >>>text$<<<
    func variable() -> StringParser<Variable> {
        return (variableName >>- { name in
            switch name.characters.last! {
            case "$":
                return create(.stringType(name: name, autodeclared: true))
            case "%":
                return create(.integerType(name: name, autodeclared: true))
            case "&":
                return create(.longType(name: name, autodeclared: true))
            case "!":
                return create(.singleType(name: name, autodeclared: true))
            case "#":
                return create(.doubleType(name: name, autodeclared: true))
                
            default:
                return create(.local(name))
            }
            })()
    }
    
    // PRINT >>>text<<<$
    func variableName() -> StringParser<String> {
        return (letter >>- { firstLetter in
            many(alphaNum) >>- { nextChars in
                option("", self.variableTypeString) >>- { varTypeString in
                    create(String([firstLetter] + nextChars) + varTypeString)
                }
            }
            })()
    }
    
    func variableTypeString() -> StringParser<String> {
        return (oneOf("$%&!#") >>- { create(String($0)) })()
    }
}

// MARK: - Commands
extension QBasicParser {
    
    //FOR x = 1 TO 10 STEP 1
    //    PRINT "SchoolFreeware"
    //NEXT x
    func forLoop() -> StringParser<Statement?> {
        return (spaces >>> Keyword.FOR >>> spaces >>> variableName <<< spaces >>- { varName in
            string("=") >>> spaces >>> self.expression <<< spaces >>- { start in
                Keyword.TO >>> spaces >>> self.expression <<< spaces >>- { end in
                    option(Expression.literals([.numberInt("1")]), Keyword.STEP >>> spaces >>> self.expression)
                        <<< endOfLine >>- { step in
                            self.statements >>- { block in
                                spaces >>> Keyword.NEXT >>> spaces >>> string(varName) >>- { _ in
                                    create(.forLoop(index: .local(varName),
                                                    start: start,
                                                    end: end,
                                                    step: step,
                                                    block: block))
                                }
                            }
                    }
                }
            }
        })()
    }
    
    // CLS
    func clsCommand() -> StringParser<Statement?> {
        return (spaces >>> Keyword.CLS <<< spaces <<< endOfLine >>- { _ in return create(.cls) })()
    }
    
    // PRINT "Hey"
    func printCommand() -> StringParser<Statement?> {
        return (spaces >>> Keyword.PRINT >>> spaces >>> expression <<< spaces <<< endOfLine
            >>- { expression in return create(.print(expression)) })()
    }
    
    // GOTO 10
    func goto() -> StringParser<Statement?> {
        return (spaces >>> Keyword.GOTO >>> spaces >>> labelIdentifier <<< spaces >>- { labelId in
            create( .goto(label: Label(name: labelId)))
            })()
    }
    
    // DIM Num1 AS INTEGER
    // DIM Num2 AS LONG
    // DIM Num3 AS SINGLE
    // DIM Num4 AS DOUBLE
    // DIM Header AS STRING
    func declaration() -> StringParser<Statement?> {
        return (spaces >>> Keyword.DIM >>> spaces >>> variableName <<< spaces >>- { varName in
            Keyword.AS >>> space >>- { _ in
                attempt(Keyword.INTEGER) <<< spaces <<< endOfLine >>- { _ in
                    return create(.declaration(.integerType(name: varName, autodeclared: false)))
                    }
                    <|> attempt(Keyword.LONG <<< spaces <<< endOfLine) >>- { _ in
                        return create(.declaration(.longType(name: varName, autodeclared: false)))
                    }
                    <|> attempt(Keyword.SINGLE <<< spaces <<< endOfLine) >>- { _ in
                        return create(.declaration(.singleType(name: varName, autodeclared: false)))
                    }
                    <|> attempt(Keyword.DOUBLE <<< spaces <<< endOfLine) >>- { _ in
                        return create(.declaration(.doubleType(name: varName, autodeclared: false)))
                    }
                    <|> attempt(Keyword.STRING <<< spaces <<< endOfLine) >>- { _ in
                        return create(.declaration(.stringType(name: varName, autodeclared: false)))
                }
            }
            })()
    }
    

}

// MARK: - Literals
extension QBasicParser {
    func literals() -> StringParser<[Literal]> {
        return (
            many1(
                attempt(floatNumberLiteral)
                    <|> attempt(intNumberLiteral)
                    <|> attempt(stringLiteral)
                    <|> attempt(variableLiteral)
                    <|> attempt(operatorLiteral)
                )
                >>- { create($0) }
            )()
    }
    
    func stringLiteral() -> StringParser<Literal> {
        return (between(quote, quote, (many1(noneOf("\"")))) >>- { create(.string(String($0))) })()
    }
    
    func quote() -> StringParser<Character> {
        return (char("\""))()
    }
    
    func variableLiteral() -> StringParser<Literal> {
        return (variableName >>- { create(.vaiableName(String($0))) })()
    }
    
    func intNumberLiteral() -> StringParser<Literal> {
        return (many1(digit) >>- { create(.numberInt(String($0))) })()
    }
    
    func floatNumberLiteral() -> StringParser<Literal> {
        return (intNumberLiteral <<< char(".") >>- { intLiteral in
            many1(digit) >>- { fractional in
                guard case .numberInt(let intString) = intLiteral else { fatalError()}
                return create(.numberFloat(String(intString) + "." + String(fractional)))
            }
            })()
    }

    // T$ = "Test"
    func assignment() -> StringParser<Statement?> {
        return ((spaces >>> variable <<< spaces <<< string("=") <<< spaces) >>- { var_ in
            self.expression <<< endOfLine >>- { exp in
                create(.assignment(var_, exp))
            }
        })()
    }
    
    func comment() -> StringParser<Statement?> {
        return(attempt(remComment) <|> attempt(shorthandComment))()
    }
    
    // REM Comment
    func remComment() -> StringParser<Statement?> {
        return (spaces >>> Keyword.REM >>> manyTill(anyToken, endOfLine) >>- {
            create(.comment(String($0)))
        })()
    }
    
    // ' another style of comment
    func shorthandComment() -> StringParser<Statement?> {
        return (spaces >>> char("'") >>> manyTill(anyToken, endOfLine) >>- {
            create(.comment(String($0)))
        })()
    }
}

// MARK: - Epressions
extension QBasicParser {

    func expression() -> StringParser<Expression> {
        return (
            attempt(literals) >>- { create(.literals($0)) }
                <|> attempt(variable) >>- { create(.variable($0))}
            )()
    }
}

// MARK: - Operators
extension QBasicParser {

    func operatorLiteral() -> StringParser<Literal> {
        return (
            attempt(equalOperator)
                <|> attempt(plusOperator)
                <|> attempt(minusOperator)
                <|> attempt(leftBracket)
                <|> attempt(rightBracket)
                <|> attempt(lessThan)
                <|> attempt(greaterThan)
                <|> attempt(modulo)
                <|> attempt(comma)
                <|> attempt(semicolon)
                <|> attempt(multiplication)
                <|> attempt(division)
            )()
    }
    
    func equalOperator() -> StringParser<Literal> {
        return (spaces >>> char("=") <<< spaces >>- { _ in create(.op(.equal))})()
    }
    
    func plusOperator() -> StringParser<Literal> {
        return (spaces >>> char("+") <<< spaces >>- { _ in create(.op(.plus))})()
    }
    
    func minusOperator() -> StringParser<Literal> {
        return (spaces >>> char("-") <<< spaces >>- { _ in create(.op(.minus))})()
    }
    
    func leftBracket() -> StringParser<Literal> {
        return (spaces >>> char("(") <<< spaces >>- { _ in create(.op(.leftBracket))})()
    }
    
    func rightBracket() -> StringParser<Literal> {
        return (spaces >>> char(")") <<< spaces >>- { _ in create(.op(.rightBracket))})()
    }
    
    func lessThan() -> StringParser<Literal> {
        return (spaces >>> char("<") <<< spaces >>- { _ in create(.op(.lessThan))})()
    }
    
    func greaterThan() -> StringParser<Literal> {
        return (spaces >>> char(">") <<< spaces >>- { _ in create(.op(.greaterThan))})()
    }
    
    func modulo() -> StringParser<Literal> {
        return (spaces >>> string("MOD") <<< spaces >>- { _ in create(.op(.modulo))})()
    }
    
    func comma() -> StringParser<Literal> {
        return (spaces >>> char(",") <<< spaces >>- { _ in create(.op(.comma))})()
    }
    
    func semicolon() -> StringParser<Literal> {
        return (spaces >>> char(";") <<< spaces >>- { _ in create(.op(.semicolon))})()
    }
    
    func multiplication() -> StringParser<Literal> {
        return (spaces >>> char("*") <<< spaces >>- { _ in create(.op(.multiplication))})()
    }
    
    func division() -> StringParser<Literal> {
        return (spaces >>> char("/") <<< spaces >>- { _ in create(.op(.division))})()
    }
}