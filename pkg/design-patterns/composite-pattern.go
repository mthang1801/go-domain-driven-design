package designpatterns

import (
	"fmt"
	"strconv"
	"strings"
)

type Expression interface {
	Accept(ExpressionVisitor)
}

type ExpressionVisitor interface {
	VisitConstant(*Constant)
	VisitVariable(*Variable)
	VisitBinaryOperation(BinaryOperation)
}

type Constant struct {
	value float64
}

func NewConstant(value float64) *Constant {
	return &Constant{value: value}
}

func (c *Constant) Accept(v ExpressionVisitor) {
	v.VisitConstant(c)
}

func (c *Constant) Value() float64 {
	return c.value
}

type Variable struct {
	name string
}

func NewVariable(name string) *Variable {
	return &Variable{
		name: name,
	}
}

func (v *Variable) Accept(visitor ExpressionVisitor) {
	visitor.VisitVariable(v)
}

func (v *Variable) Name() string {
	return v.name
}

type BinaryOperation interface {
	Expression
	Left() Expression
	Right() Expression
}

type BinaryOperationImpl struct {
	left, right Expression
}

func (o *BinaryOperationImpl) Left() Expression {
	return o.left
}

func (o *BinaryOperationImpl) Right() Expression {
	return o.right
}

type Add struct {
	BinaryOperationImpl
}

func NewAdd(left, right Expression) *Add {
	return &Add{BinaryOperationImpl{left, right}}
}

func (a *Add) Accept(v ExpressionVisitor) {
	v.VisitBinaryOperation(a)
}

type Subtract struct {
	BinaryOperationImpl
}

func NewSubtract(left, right Expression) *Subtract {
	return &Subtract{BinaryOperationImpl{left, right}}
}

func (s *Subtract) Accept(v ExpressionVisitor) {
	v.VisitBinaryOperation(s)
}

type Multiply struct {
	BinaryOperationImpl
}

func NewMultiply(left, right Expression) *Multiply {
	return &Multiply{BinaryOperationImpl{left, right}}
}

func (m *Multiply) Accept(v ExpressionVisitor) {
	v.VisitBinaryOperation(m)
}

type Divide struct {
	BinaryOperationImpl
}

func NewDivide(left, right Expression) *Divide {
	return &Divide{BinaryOperationImpl{left, right}}
}

func (m *Divide) Accept(v ExpressionVisitor) {
	v.VisitBinaryOperation(m)
}

type EvaluateVisitor struct {
	result    float64
	variables map[string]float64
}

func NewEvaluateVisitor(variables map[string]float64) *EvaluateVisitor {
	return &EvaluateVisitor{variables: variables}
}

func (v *EvaluateVisitor) VisitConstant(c *Constant) {
	v.result = c.Value()
}

func (v *EvaluateVisitor) VisitVariable(variable *Variable) {
	value, exists := v.variables[variable.Name()]
	if !exists {
		panic(fmt.Sprintf("Variable %s not defined", variable.Name()))
	}
	v.result = value
}

func (v *EvaluateVisitor) VisitBinaryOperation(op BinaryOperation) {
	op.Left().Accept(v)
	left := v.result
	op.Right().Accept(v)
	right := v.result

	switch op.(type) {
	case *Add:
		v.result = left + right
	case *Subtract:
		v.result = left - right
	case *Multiply:
		v.result = left * right
	case *Divide:
		if right == 0 {
			panic("Division by zero")
		}
		v.result = left / right
	}
}

func (v *EvaluateVisitor) Result() float64 {
	return v.result
}

type ToStringVisitor struct {
	result string
}

func NewToStringVisitor() *ToStringVisitor {
	return &ToStringVisitor{}
}

func (v *ToStringVisitor) VisitConstant(c *Constant) {
	v.result = fmt.Sprintf("%v", c.Value())
}

func (v *ToStringVisitor) VisitVariable(variable *Variable) {
	v.result = variable.Name()
}

func (v *ToStringVisitor) VisitBinaryOperation(op BinaryOperation) {
	op.Left().Accept(v)
	left := v.result
	op.Right().Accept(v)
	right := v.result

	var operation string
	switch op.(type) {
	case *Add:
		operation = "+"
	case *Subtract:
		operation = "-"
	case *Multiply:
		operation = "*"
	case *Divide:
		operation = "/"
	}

	v.result = fmt.Sprintf("(%s %s %s)", left, operation, right)
}

func (v *ToStringVisitor) Result() string {
	return v.result
}

type SimplifyVisitor struct {
	result Expression
}

func NewSimplifyVisitor() *SimplifyVisitor {
	return &SimplifyVisitor{}
}

func (v *SimplifyVisitor) VisitConstant(c *Constant) {
	v.result = c
}

func (v *SimplifyVisitor) VisitVariable(variable *Variable) {
	v.result = variable
}

func (v *SimplifyVisitor) VisitBinaryOperation(op BinaryOperation) {
	op.Left().Accept(v)
	left := v.result
	op.Right().Accept(v)
	right := v.result

	if _, ok := left.(*Constant); ok {
		if _, ok := right.(*Constant); ok {
			evalVisitor := NewEvaluateVisitor(nil)
			op.Accept(evalVisitor)
			v.result = NewConstant(evalVisitor.Result())
			return
		}
	}

	if _, ok := op.(*Multiply); ok {
		if c, ok := left.(*Constant); ok && c.Value() == 1 {
			v.result = right
			return
		}
		if c, ok := left.(*Constant); ok && c.Value() == 0 {
			v.result = NewConstant(0)
			return
		}
		if c, ok := right.(*Constant); ok && c.Value() == 1 {
			v.result = left
			return
		}
		if c, ok := right.(*Constant); ok && c.Value() == 0 {
			v.result = left
			return
		}
	}

	if _, ok := op.(*Add); ok {
		if c, ok := left.(*Constant); ok && c.Value() == 0 {
			v.result = right
			return
		}
		if c, ok := right.(*Constant); ok && c.Value() == 0 {
			v.result = left
			return
		}
	}

	switch op.(type) {
	case *Add:
		v.result = NewAdd(left, right)
	case *Subtract:
		v.result = NewSubtract(left, right)
	case *Multiply:
		v.result = NewMultiply(left, right)
	case *Divide:
		v.result = NewDivide(left, right)
	}
}

func (v *SimplifyVisitor) Result() Expression {
	return v.result
}

// Parser
type Parser struct {
	tokens   []string
	position int
}

func NewParser(input string) *Parser {
	return &Parser{tokens: tokenize(input), position: 0}
}

func tokenize(input string) []string {
	input = strings.ReplaceAll(input, " ", "")
	tokens := []string{}
	i := 0
	for i < len(input) {
		if input[i] == '$' && i+1 < len(input) && input[i+1] >= '0' && input[i+1] <= '9' {
			varToken := "$"
			i++
			numStr := ""
			for i < len(input) && input[i] >= '0' && input[i] <= '9' {
				numStr += string(input[i])
				i++
			}
			if len(numStr) > 0 {
				varToken += numStr
				tokens = append(tokens, varToken)
				continue
			}
			panic(fmt.Sprintf("Invalid parameter syntax at position %d", i))
		}
		if input[i] >= '0' && input[i] <= '9' {
			num := ""
			for i < len(input) && (input[i] == '.' || (input[i] >= '0' && input[i] <= '9')) {
				num += string(input[i])
				i++
			}
			tokens = append(tokens, num)
			continue
		}
		if strings.Contains("+-*/()", string(input[i])) {
			tokens = append(tokens, string(input[i]))
			i++
		} else {
			panic(fmt.Sprintf("Unexpected character '%c' at position %d", input[i], i))
		}
	}
	return tokens
}

func (p *Parser) Parse() Expression {
	return p.parseExpression()
}

func (p *Parser) parseExpression() Expression {
	expr := p.parseTerm()
	for p.position < len(p.tokens) && (p.tokens[p.position] == "+" || p.tokens[p.position] == "-") {
		op := p.tokens[p.position]
		p.position++
		right := p.parseTerm()
		if op == "+" {
			expr = NewAdd(expr, right)
		} else {
			expr = NewSubtract(expr, right)
		}
	}
	return expr
}

func (p *Parser) parseTerm() Expression {
	expr := p.parseFactor()
	for p.position < len(p.tokens) && (p.tokens[p.position] == "*" || p.tokens[p.position] == "/") {
		op := p.tokens[p.position]
		p.position++
		right := p.parseFactor()
		if op == "*" {
			expr = NewMultiply(expr, right)
		} else {
			expr = NewDivide(expr, right)
		}
	}
	return expr
}

func (p *Parser) parseFactor() Expression {
	if p.position >= len(p.tokens) {
		panic("Unexpected end of input")
	}

	token := p.tokens[p.position]
	p.position++

	if token == "(" {
		expr := p.parseExpression()
		if p.position >= len(p.tokens) || p.tokens[p.position] != ")" {
			panic("Expected closing parenthesis")
		}
		p.position++
		return expr
	}

	if num, err := strconv.ParseFloat(token, 64); err == nil {
		return NewConstant(num)
	}

	if len(token) > 1 && token[0] == '$' && token[1] >= '0' && token[1] <= '9' {
		return NewVariable(token)
	}

	panic(fmt.Sprintf("Invalid token: %s", token))
}

func main() {
	formular := "($0*(1-$1))+$2+$3/$4 * 100"
	variables := map[string]float64{
		"$0": 100,
		"$1": 0.2,
		"$2": 10,
		"$3": 5,
	}

	fmt.Println(formular, variables)

	parser := NewParser(formular)
	expr := parser.Parse()

	// In biểu thức gốc
	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	original := toStringVisitor.Result()

	// Simplify biểu thức
	simplifyVisitor := NewSimplifyVisitor()
	expr.Accept(simplifyVisitor)
	expr = simplifyVisitor.Result()

	// // In biểu thức đã simplify
	toStringVisitor = NewToStringVisitor()
	expr.Accept(toStringVisitor)
	simplified := toStringVisitor.Result()

	// // Tính toán giá
	evalVisitor := NewEvaluateVisitor(variables)
	expr.Accept(evalVisitor)
	finalPrice := evalVisitor.Result()

	// result := map[string]interface{}{
	// 	"original":   original,
	// 	"simplified": simplified,
	// 	"finalPrice": finalPrice,
	// }

	fmt.Printf("Original: %s\n", original)
	fmt.Printf("Simplified: %s\n", simplified)
	fmt.Printf("Final Price: %v\n", finalPrice)
}
