DECLARE FUNCTION Power! (x AS SINGLE, y AS SINGLE)
DIM Num1 AS SINGLE
DIM Num2 AS SINGLE
DIM Answer AS SINGLE

CLS

INPUT "Enter First Number: ", Num1
INPUT "Enter Second Number: ", Num2

Answer = Power!(Num1, Num2)

PRINT "The Answer Is:"; Answer

PRINT STR$(158)

FUNCTION Power! (x AS SINGLE, y AS SINGLE)
Power! = x + y
END FUNCTION
~~~~~~~~~~~~~~~~~~~~
KEYWORD     	#@# DECLARE
KEYWORD     	#@# FUNCTION
IDENTIFIER  	#@# Power!
OPERATOR    	#@# (
IDENTIFIER  	#@# x
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
OPERATOR    	#@# ,
IDENTIFIER  	#@# y
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
OPERATOR    	#@# )
KEYWORD     	#@# DIM
IDENTIFIER  	#@# Num1
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
KEYWORD     	#@# DIM
IDENTIFIER  	#@# Num2
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
KEYWORD     	#@# DIM
IDENTIFIER  	#@# Answer
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
KEYWORD     	#@# CLS
KEYWORD     	#@# INPUT
STRING      	#@# Enter First Number: 
OPERATOR    	#@# ,
IDENTIFIER  	#@# Num1
KEYWORD     	#@# INPUT
STRING      	#@# Enter Second Number: 
OPERATOR    	#@# ,
IDENTIFIER  	#@# Num2
IDENTIFIER  	#@# Answer
OPERATOR    	#@# =
IDENTIFIER  	#@# Power!
OPERATOR    	#@# (
IDENTIFIER  	#@# Num1
OPERATOR    	#@# ,
IDENTIFIER  	#@# Num2
OPERATOR    	#@# )
KEYWORD     	#@# PRINT
STRING      	#@# The Answer Is:
OPERATOR    	#@# ;
IDENTIFIER  	#@# Answer
KEYWORD     	#@# PRINT
IDENTIFIER  	#@# ST
IDENTIFIER  	#@# R$
OPERATOR    	#@# (
NUMBER      	#@# 158
OPERATOR    	#@# )
KEYWORD     	#@# FUNCTION
IDENTIFIER  	#@# Power!
OPERATOR    	#@# (
IDENTIFIER  	#@# x
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
OPERATOR    	#@# ,
IDENTIFIER  	#@# y
KEYWORD     	#@# AS
KEYWORD     	#@# SINGLE
OPERATOR    	#@# )
IDENTIFIER  	#@# Power!
OPERATOR    	#@# =
IDENTIFIER  	#@# x
OPERATOR    	#@# +
IDENTIFIER  	#@# y
KEYWORD     	#@# END
KEYWORD     	#@# FUNCTION
~~~~~~~~~~~~~~~~~~~~
// User functions
func Power__single(y: Double, x: Double) -> Double {
    return x+y
}
_ = {
    // Main loop vars declaration
    var Num2: Double = 0
    var Num1: Double = 0
    var Answer: Double = 0
    // CLS is not implemented yet
    print("Enter First Number: ", terminator: "")
    Num1 = Double(readLine() ?? "") ?? 0
    print("Enter Second Number: ", terminator: "")
    Num2 = Double(readLine() ?? "") ?? 0
    Answer &= Power__single(y: Num1, x: Num2)
    print("\("The Answer Is:")"+"\(Answer)", terminator: "\n")
    print("\(STR__string(158))", terminator: "\n")
}()
