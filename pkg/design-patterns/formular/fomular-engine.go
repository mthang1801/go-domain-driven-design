package main

import (
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"
	"unicode"
)

// ============================================================================
// CORE INTERFACES - Composite Pattern
// ============================================================================

type Expression interface {
	Accept(Visitor) interface{}
	Type() ExpressionType
}

type ExpressionType string

const (
	TypeNumber  ExpressionType = "number"
	TypeString  ExpressionType = "string"
	TypeBoolean ExpressionType = "boolean"
	TypeArray   ExpressionType = "array"
	TypeDate    ExpressionType = "date"
	TypeNull    ExpressionType = "null"
)

// ============================================================================
// VISITOR PATTERN
// ============================================================================

type Visitor interface {
	VisitConstant(*Constant) interface{}
	VisitVariable(*Variable) interface{}
	VisitBinaryOperation(BinaryOperation) interface{}
	VisitUnaryOperation(UnaryOperation) interface{}
	VisitFunctionCall(*FunctionCall) interface{}
}

// ============================================================================
// LEAF NODES - Constants & Variables
// ============================================================================

type Constant struct {
	value interface{}
	typ   ExpressionType
}

func NewConstant(value interface{}) *Constant {
	return &Constant{value: value, typ: inferType(value)}
}

func (c *Constant) Accept(v Visitor) interface{} {
	return v.VisitConstant(c)
}

func (c *Constant) Type() ExpressionType {
	return c.typ
}

func (c *Constant) Value() interface{} {
	return c.value
}

type Variable struct {
	name string
}

func NewVariable(name string) *Variable {
	return &Variable{name: name}
}

func (v *Variable) Accept(visitor Visitor) interface{} {
	return visitor.VisitVariable(v)
}

func (v *Variable) Type() ExpressionType {
	return TypeNumber
}

func (v *Variable) Name() string {
	return v.name
}

// ============================================================================
// COMPOSITE NODES - Operations
// ============================================================================

type BinaryOperation interface {
	Expression
	Left() Expression
	Right() Expression
	Operator() string
}

type BinaryOperationImpl struct {
	left, right Expression
	operator    string
}

func (b *BinaryOperationImpl) Left() Expression     { return b.left }
func (b *BinaryOperationImpl) Right() Expression    { return b.right }
func (b *BinaryOperationImpl) Operator() string     { return b.operator }
func (b *BinaryOperationImpl) Type() ExpressionType { return TypeBoolean }

// Arithmetic Operations
type Add struct{ BinaryOperationImpl }
type Subtract struct{ BinaryOperationImpl }
type Multiply struct{ BinaryOperationImpl }
type Divide struct{ BinaryOperationImpl }
type Modulo struct{ BinaryOperationImpl }
type Power struct{ BinaryOperationImpl }

func NewAdd(l, r Expression) *Add           { return &Add{BinaryOperationImpl{l, r, "+"}} }
func NewSubtract(l, r Expression) *Subtract { return &Subtract{BinaryOperationImpl{l, r, "-"}} }
func NewMultiply(l, r Expression) *Multiply { return &Multiply{BinaryOperationImpl{l, r, "*"}} }
func NewDivide(l, r Expression) *Divide     { return &Divide{BinaryOperationImpl{l, r, "/"}} }
func NewModulo(l, r Expression) *Modulo     { return &Modulo{BinaryOperationImpl{l, r, "%"}} }
func NewPower(l, r Expression) *Power       { return &Power{BinaryOperationImpl{l, r, "^"}} }

func (op *Add) Accept(v Visitor) interface{}      { return v.VisitBinaryOperation(op) }
func (op *Subtract) Accept(v Visitor) interface{} { return v.VisitBinaryOperation(op) }
func (op *Multiply) Accept(v Visitor) interface{} { return v.VisitBinaryOperation(op) }
func (op *Divide) Accept(v Visitor) interface{}   { return v.VisitBinaryOperation(op) }
func (op *Modulo) Accept(v Visitor) interface{}   { return v.VisitBinaryOperation(op) }
func (op *Power) Accept(v Visitor) interface{}    { return v.VisitBinaryOperation(op) }

// Comparison Operations
type Equal struct{ BinaryOperationImpl }
type NotEqual struct{ BinaryOperationImpl }
type GreaterThan struct{ BinaryOperationImpl }
type GreaterThanOrEqual struct{ BinaryOperationImpl }
type LessThan struct{ BinaryOperationImpl }
type LessThanOrEqual struct{ BinaryOperationImpl }
type In struct{ BinaryOperationImpl }
type Between struct {
	value Expression
	lower Expression
	upper Expression
}

func NewEqual(l, r Expression) *Equal       { return &Equal{BinaryOperationImpl{l, r, "="}} }
func NewNotEqual(l, r Expression) *NotEqual { return &NotEqual{BinaryOperationImpl{l, r, "!="}} }
func NewGreaterThan(l, r Expression) *GreaterThan {
	return &GreaterThan{BinaryOperationImpl{l, r, ">"}}
}
func NewGreaterThanOrEqual(l, r Expression) *GreaterThanOrEqual {
	return &GreaterThanOrEqual{BinaryOperationImpl{l, r, ">="}}
}
func NewLessThan(l, r Expression) *LessThan { return &LessThan{BinaryOperationImpl{l, r, "<"}} }
func NewLessThanOrEqual(l, r Expression) *LessThanOrEqual {
	return &LessThanOrEqual{BinaryOperationImpl{l, r, "<="}}
}
func NewIn(l, r Expression) *In { return &In{BinaryOperationImpl{l, r, "IN"}} }

func NewBetween(value, lower, upper Expression) *Between {
	return &Between{value: value, lower: lower, upper: upper}
}

func (op *Equal) Accept(v Visitor) interface{}              { return v.VisitBinaryOperation(op) }
func (op *NotEqual) Accept(v Visitor) interface{}           { return v.VisitBinaryOperation(op) }
func (op *GreaterThan) Accept(v Visitor) interface{}        { return v.VisitBinaryOperation(op) }
func (op *GreaterThanOrEqual) Accept(v Visitor) interface{} { return v.VisitBinaryOperation(op) }
func (op *LessThan) Accept(v Visitor) interface{}           { return v.VisitBinaryOperation(op) }
func (op *LessThanOrEqual) Accept(v Visitor) interface{}    { return v.VisitBinaryOperation(op) }
func (op *In) Accept(v Visitor) interface{}                 { return v.VisitBinaryOperation(op) }

func (b *Between) Accept(v Visitor) interface{} {
	and := NewAnd(
		NewGreaterThanOrEqual(b.value, b.lower),
		NewLessThanOrEqual(b.value, b.upper),
	)
	return and.Accept(v)
}
func (b *Between) Type() ExpressionType { return TypeBoolean }

// Logical Operations
type And struct{ BinaryOperationImpl }
type Or struct{ BinaryOperationImpl }

func NewAnd(l, r Expression) *And { return &And{BinaryOperationImpl{l, r, "AND"}} }
func NewOr(l, r Expression) *Or   { return &Or{BinaryOperationImpl{l, r, "OR"}} }

func (op *And) Accept(v Visitor) interface{} { return v.VisitBinaryOperation(op) }
func (op *Or) Accept(v Visitor) interface{}  { return v.VisitBinaryOperation(op) }

// Unary Operations
type UnaryOperation interface {
	Expression
	Operand() Expression
	Operator() string
}

type UnaryOperationImpl struct {
	operand  Expression
	operator string
}

func (u *UnaryOperationImpl) Operand() Expression  { return u.operand }
func (u *UnaryOperationImpl) Operator() string     { return u.operator }
func (u *UnaryOperationImpl) Type() ExpressionType { return TypeBoolean }

type Not struct{ UnaryOperationImpl }
type Negate struct{ UnaryOperationImpl }
type IsNull struct{ UnaryOperationImpl }
type IsNotNull struct{ UnaryOperationImpl }

func NewNot(operand Expression) *Not       { return &Not{UnaryOperationImpl{operand, "NOT"}} }
func NewNegate(operand Expression) *Negate { return &Negate{UnaryOperationImpl{operand, "-"}} }
func NewIsNull(operand Expression) *IsNull { return &IsNull{UnaryOperationImpl{operand, "IS NULL"}} }
func NewIsNotNull(operand Expression) *IsNotNull {
	return &IsNotNull{UnaryOperationImpl{operand, "IS NOT NULL"}}
}

func (op *Not) Accept(v Visitor) interface{}       { return v.VisitUnaryOperation(op) }
func (op *Negate) Accept(v Visitor) interface{}    { return v.VisitUnaryOperation(op) }
func (op *IsNull) Accept(v Visitor) interface{}    { return v.VisitUnaryOperation(op) }
func (op *IsNotNull) Accept(v Visitor) interface{} { return v.VisitUnaryOperation(op) }

// ============================================================================
// FUNCTION CALLS
// ============================================================================

type FunctionCall struct {
	name      string
	arguments []Expression
}

func NewFunctionCall(name string, args []Expression) *FunctionCall {
	return &FunctionCall{name: name, arguments: args}
}

func (f *FunctionCall) Accept(v Visitor) interface{} {
	return v.VisitFunctionCall(f)
}

func (f *FunctionCall) Type() ExpressionType {
	return TypeNumber
}

func (f *FunctionCall) Name() string {
	return f.name
}

func (f *FunctionCall) Arguments() []Expression {
	return f.arguments
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

func inferType(value interface{}) ExpressionType {
	switch value.(type) {
	case float64, int, int64:
		return TypeNumber
	case string:
		return TypeString
	case bool:
		return TypeBoolean
	case []interface{}:
		return TypeArray
	case time.Time:
		return TypeDate
	case nil:
		return TypeNull
	default:
		return TypeString
	}
}

func ToFloat64(v interface{}) (float64, error) {
	switch val := v.(type) {
	case float64:
		return val, nil
	case int:
		return float64(val), nil
	case int64:
		return float64(val), nil
	default:
		return 0, fmt.Errorf("cannot convert %T to float64", v)
	}
}

func ToBool(v interface{}) (bool, error) {
	switch val := v.(type) {
	case bool:
		return val, nil
	case float64:
		return val != 0, nil
	case int:
		return val != 0, nil
	default:
		return false, fmt.Errorf("cannot convert %T to bool", v)
	}
}

// ============================================================================
// EVALUATE VISITOR
// ============================================================================

type EvaluateVisitor struct {
	variables map[string]interface{}
	functions map[string]func([]interface{}) interface{}
}

func NewEvaluateVisitor(variables map[string]interface{}) *EvaluateVisitor {
	v := &EvaluateVisitor{
		variables: variables,
		functions: make(map[string]func([]interface{}) interface{}),
	}
	v.registerBuiltinFunctions()
	return v
}

func (v *EvaluateVisitor) registerBuiltinFunctions() {
	v.functions["SUM"] = func(args []interface{}) interface{} {
		sum := 0.0
		for _, arg := range args {
			if num, err := ToFloat64(arg); err == nil {
				sum += num
			}
		}
		return sum
	}

	v.functions["AVG"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		sum := 0.0
		count := 0
		for _, arg := range args {
			if num, err := ToFloat64(arg); err == nil {
				sum += num
				count++
			}
		}
		return sum / float64(count)
	}

	v.functions["MAX"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		max := math.Inf(-1)
		for _, arg := range args {
			if num, err := ToFloat64(arg); err == nil && num > max {
				max = num
			}
		}
		return max
	}

	v.functions["MIN"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		min := math.Inf(1)
		for _, arg := range args {
			if num, err := ToFloat64(arg); err == nil && num < min {
				min = num
			}
		}
		return min
	}

	v.functions["ABS"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		if num, err := ToFloat64(args[0]); err == nil {
			return math.Abs(num)
		}
		return 0.0
	}

	v.functions["ROUND"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		num, _ := ToFloat64(args[0])
		precision := 0.0
		if len(args) > 1 {
			precision, _ = ToFloat64(args[1])
		}
		multiplier := math.Pow(10, precision)
		return math.Round(num*multiplier) / multiplier
	}

	v.functions["CEIL"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		if num, err := ToFloat64(args[0]); err == nil {
			return math.Ceil(num)
		}
		return 0.0
	}

	v.functions["FLOOR"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return 0.0
		}
		if num, err := ToFloat64(args[0]); err == nil {
			return math.Floor(num)
		}
		return 0.0
	}

	v.functions["IF"] = func(args []interface{}) interface{} {
		if len(args) < 2 {
			return nil
		}
		condition, _ := ToBool(args[0])
		if condition {
			return args[1]
		}
		if len(args) > 2 {
			return args[2]
		}
		return nil
	}

	v.functions["AND"] = func(args []interface{}) interface{} {
		for _, arg := range args {
			if val, err := ToBool(arg); err != nil || !val {
				return false
			}
		}
		return true
	}

	v.functions["OR"] = func(args []interface{}) interface{} {
		for _, arg := range args {
			if val, err := ToBool(arg); err == nil && val {
				return true
			}
		}
		return false
	}

	v.functions["NOT"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return true
		}
		val, _ := ToBool(args[0])
		return !val
	}

	v.functions["CONCAT"] = func(args []interface{}) interface{} {
		var result strings.Builder
		for _, arg := range args {
			result.WriteString(fmt.Sprintf("%v", arg))
		}
		return result.String()
	}

	v.functions["UPPER"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return ""
		}
		return strings.ToUpper(fmt.Sprintf("%v", args[0]))
	}

	v.functions["LOWER"] = func(args []interface{}) interface{} {
		if len(args) == 0 {
			return ""
		}
		return strings.ToLower(fmt.Sprintf("%v", args[0]))
	}
}

func (v *EvaluateVisitor) VisitConstant(c *Constant) interface{} {
	return c.Value()
}

func (v *EvaluateVisitor) VisitVariable(variable *Variable) interface{} {
	value, exists := v.variables[variable.Name()]
	if !exists {
		panic(fmt.Sprintf("Variable %s not defined", variable.Name()))
	}
	return value
}

func (v *EvaluateVisitor) VisitBinaryOperation(op BinaryOperation) interface{} {
	left := op.Left().Accept(v)
	right := op.Right().Accept(v)

	switch op.(type) {
	case *Add:
		l, _ := ToFloat64(left)
		r, _ := ToFloat64(right)
		return l + r
	case *Subtract:
		l, _ := ToFloat64(left)
		r, _ := ToFloat64(right)
		return l - r
	case *Multiply:
		l, _ := ToFloat64(left)
		r, _ := ToFloat64(right)
		return l * r
	case *Divide:
		l, _ := ToFloat64(left)
		r, _ := ToFloat64(right)
		if r == 0 {
			panic("Division by zero")
		}
		return l / r
	case *Modulo:
		l, _ := ToFloat64(left)
		r, _ := ToFloat64(right)
		return math.Mod(l, r)
	case *Power:
		l, _ := ToFloat64(left)
		r, _ := ToFloat64(right)
		return math.Pow(l, r)
	case *Equal:
		return v.compareValues(left, right) == 0
	case *NotEqual:
		return v.compareValues(left, right) != 0
	case *GreaterThan:
		return v.compareValues(left, right) > 0
	case *GreaterThanOrEqual:
		return v.compareValues(left, right) >= 0
	case *LessThan:
		return v.compareValues(left, right) < 0
	case *LessThanOrEqual:
		return v.compareValues(left, right) <= 0
	case *In:
		return v.checkIn(left, right)
	case *And:
		l, _ := ToBool(left)
		r, _ := ToBool(right)
		return l && r
	case *Or:
		l, _ := ToBool(left)
		r, _ := ToBool(right)
		return l || r
	}

	return nil
}

func (v *EvaluateVisitor) VisitUnaryOperation(op UnaryOperation) interface{} {
	operand := op.Operand().Accept(v)

	switch op.(type) {
	case *Not:
		val, _ := ToBool(operand)
		return !val
	case *Negate:
		num, _ := ToFloat64(operand)
		return -num
	case *IsNull:
		return operand == nil
	case *IsNotNull:
		return operand != nil
	}

	return nil
}

func (v *EvaluateVisitor) VisitFunctionCall(f *FunctionCall) interface{} {
	fn, exists := v.functions[strings.ToUpper(f.Name())]
	if !exists {
		panic(fmt.Sprintf("Function %s not defined", f.Name()))
	}

	args := make([]interface{}, len(f.Arguments()))
	for i, arg := range f.Arguments() {
		args[i] = arg.Accept(v)
	}

	return fn(args)
}

func (v *EvaluateVisitor) compareValues(left, right interface{}) int {
	switch l := left.(type) {
	case float64:
		if r, err := ToFloat64(right); err == nil {
			if l < r {
				return -1
			} else if l > r {
				return 1
			}
			return 0
		}
	case string:
		if r, ok := right.(string); ok {
			return strings.Compare(l, r)
		}
	case time.Time:
		if r, ok := right.(time.Time); ok {
			if l.Before(r) {
				return -1
			} else if l.After(r) {
				return 1
			}
			return 0
		}
	}
	return 0
}

func (v *EvaluateVisitor) checkIn(value interface{}, list interface{}) bool {
	arr, ok := list.([]interface{})
	if !ok {
		return false
	}
	for _, item := range arr {
		if v.compareValues(value, item) == 0 {
			return true
		}
	}
	return false
}

// ============================================================================
// TO STRING VISITOR
// ============================================================================

type ToStringVisitor struct {
	result string
}

func NewToStringVisitor() *ToStringVisitor {
	return &ToStringVisitor{}
}

func (v *ToStringVisitor) Result() string {
	return v.result
}

func (v *ToStringVisitor) VisitConstant(c *Constant) interface{} {
	v.result = fmt.Sprintf("%v", c.Value())
	return nil
}

func (v *ToStringVisitor) VisitVariable(variable *Variable) interface{} {
	v.result = variable.Name()
	return nil
}

func (v *ToStringVisitor) VisitBinaryOperation(op BinaryOperation) interface{} {
	op.Left().Accept(v)
	left := v.result
	op.Right().Accept(v)
	right := v.result
	v.result = fmt.Sprintf("(%s %s %s)", left, op.Operator(), right)
	return nil
}

func (v *ToStringVisitor) VisitUnaryOperation(op UnaryOperation) interface{} {
	op.Operand().Accept(v)
	operand := v.result
	v.result = fmt.Sprintf("%s(%s)", op.Operator(), operand)
	return nil
}

func (v *ToStringVisitor) VisitFunctionCall(f *FunctionCall) interface{} {
	args := make([]string, len(f.Arguments()))
	for i, arg := range f.Arguments() {
		arg.Accept(v)
		args[i] = v.result
	}
	v.result = fmt.Sprintf("%s(%s)", f.Name(), strings.Join(args, ", "))
	return nil
}

// ============================================================================
// SQL COMPILER VISITOR
// ============================================================================

type SQLCompilerVisitor struct {
	sql        string
	paramIndex int
}

func NewSQLCompilerVisitor() *SQLCompilerVisitor {
	return &SQLCompilerVisitor{paramIndex: 1}
}

func (v *SQLCompilerVisitor) Result() string {
	return v.sql
}

func (v *SQLCompilerVisitor) VisitConstant(c *Constant) interface{} {
	switch val := c.Value().(type) {
	case string:
		v.sql = fmt.Sprintf("'%s'", val)
	case nil:
		v.sql = "NULL"
	default:
		v.sql = fmt.Sprintf("%v", val)
	}
	return nil
}

func (v *SQLCompilerVisitor) VisitVariable(variable *Variable) interface{} {
	v.sql = variable.Name()
	return nil
}

func (v *SQLCompilerVisitor) VisitBinaryOperation(op BinaryOperation) interface{} {
	op.Left().Accept(v)
	left := v.sql
	op.Right().Accept(v)
	right := v.sql

	sqlOp := v.getSQLOperator(op)
	v.sql = fmt.Sprintf("(%s %s %s)", left, sqlOp, right)
	return nil
}

func (v *SQLCompilerVisitor) VisitUnaryOperation(op UnaryOperation) interface{} {
	op.Operand().Accept(v)
	operand := v.sql

	switch op.(type) {
	case *IsNull:
		v.sql = fmt.Sprintf("%s IS NULL", operand)
	case *IsNotNull:
		v.sql = fmt.Sprintf("%s IS NOT NULL", operand)
	case *Not:
		v.sql = fmt.Sprintf("NOT %s", operand)
	case *Negate:
		v.sql = fmt.Sprintf("-%s", operand)
	}
	return nil
}

func (v *SQLCompilerVisitor) VisitFunctionCall(f *FunctionCall) interface{} {
	args := make([]string, len(f.Arguments()))
	for i, arg := range f.Arguments() {
		arg.Accept(v)
		args[i] = v.sql
	}
	v.sql = fmt.Sprintf("%s(%s)", strings.ToUpper(f.Name()), strings.Join(args, ", "))
	return nil
}

func (v *SQLCompilerVisitor) getSQLOperator(op BinaryOperation) string {
	switch op.(type) {
	case *Add:
		return "+"
	case *Subtract:
		return "-"
	case *Multiply:
		return "*"
	case *Divide:
		return "/"
	case *Equal:
		return "="
	case *NotEqual:
		return "!="
	case *GreaterThan:
		return ">"
	case *GreaterThanOrEqual:
		return ">="
	case *LessThan:
		return "<"
	case *LessThanOrEqual:
		return "<="
	case *And:
		return "AND"
	case *Or:
		return "OR"
	case *In:
		return "IN"
	default:
		return op.Operator()
	}
}

// ============================================================================
// TOKENIZER
// ============================================================================

type TokenType int

const (
	TokenNumber     TokenType = iota // 0
	TokenString                      // 1
	TokenVariable                    // 2
	TokenOperator                    // 3
	TokenFunction                    // 4
	TokenLeftParen                   // 5
	TokenRightParen                  // 6
	TokenComma                       // 7
	TokenEOF                         // 8
)

type Token struct {
	Type  TokenType
	Value string
}

type Tokenizer struct {
	input    string
	position int
	tokens   []Token
}

func NewTokenizer(input string) *Tokenizer {
	return &Tokenizer{input: input, position: 0}
}

func (t *Tokenizer) Tokenize() []Token {
	t.tokens = []Token{}

	for t.position < len(t.input) {
		t.skipWhitespace()
		if t.position >= len(t.input) {
			break
		}

		ch := t.input[t.position]

		if ch == '$' {
			t.readVariable()
			continue
		}

		if unicode.IsDigit(rune(ch)) {
			t.readNumber()
			continue
		}

		if ch == '\'' || ch == '"' {
			t.readString()
			continue
		}

		if unicode.IsLetter(rune(ch)) {
			t.readIdentifier()
			continue
		}

		if t.readOperator() {
			continue
		}

		panic(fmt.Sprintf("Unexpected character '%c' at position %d", ch, t.position))
	}

	t.tokens = append(t.tokens, Token{Type: TokenEOF, Value: ""})
	return t.tokens
}

func (t *Tokenizer) skipWhitespace() {
	for t.position < len(t.input) && unicode.IsSpace(rune(t.input[t.position])) {
		t.position++
	}
}

func (t *Tokenizer) readVariable() {
	start := t.position
	t.position++

	for t.position < len(t.input) && (unicode.IsDigit(rune(t.input[t.position])) || unicode.IsLetter(rune(t.input[t.position])) || t.input[t.position] == '_') {
		t.position++
	}

	t.tokens = append(t.tokens, Token{
		Type:  TokenVariable,
		Value: t.input[start:t.position],
	})
}

func (t *Tokenizer) readNumber() {
	start := t.position

	for t.position < len(t.input) && (unicode.IsDigit(rune(t.input[t.position])) || t.input[t.position] == '.') {
		t.position++
	}

	t.tokens = append(t.tokens, Token{
		Type:  TokenNumber,
		Value: t.input[start:t.position],
	})
}

func (t *Tokenizer) readString() {
	quote := t.input[t.position]
	t.position++
	start := t.position

	for t.position < len(t.input) && t.input[t.position] != quote {
		t.position++
	}

	if t.position >= len(t.input) {
		panic("Unterminated string")
	}

	value := t.input[start:t.position]
	t.position++

	t.tokens = append(t.tokens, Token{
		Type:  TokenString,
		Value: value,
	})
}

func (t *Tokenizer) readIdentifier() {
	start := t.position

	for t.position < len(t.input) && (unicode.IsLetter(rune(t.input[t.position])) || unicode.IsDigit(rune(t.input[t.position])) || t.input[t.position] == '_') {
		t.position++
	}

	value := t.input[start:t.position]
	upperValue := strings.ToUpper(value)

	// Handle NULL first
	if upperValue == "NULL" {
		t.tokens = append(t.tokens, Token{
			Type:  TokenString,
			Value: "NULL",
		})
		return
	}

	// Check if followed by '(' WITHOUT consuming whitespace first
	// This ensures we differentiate between "AND(" and "AND ("
	hasImmediateParenthesis := t.position < len(t.input) && t.input[t.position] == '('

	// Look ahead with whitespace skipping
	savedPos := t.position
	t.skipWhitespace()
	hasParenthesisAfterSpace := t.position < len(t.input) && t.input[t.position] == '('

	// Restore position for now
	t.position = savedPos

	// Special rules for AND, OR, IN:
	// - AND( or OR( (no space) → Function (Excel style)
	// - AND ( or OR ( (with space) → Operator (SQL style)
	// - IN always operator (even IN() would be weird)
	if hasImmediateParenthesis && (upperValue == "AND" || upperValue == "OR" || upperValue == "NOT") {
		// No space before '(' → Function call like AND(...), OR(...), NOT(...)
		t.skipWhitespace() // consume the whitespace
		t.tokens = append(t.tokens, Token{
			Type:  TokenFunction,
			Value: upperValue,
		})
		return
	}

	// IN, BETWEEN, IS are ALWAYS operators
	if upperValue == "IN" || upperValue == "BETWEEN" || upperValue == "IS" {
		t.tokens = append(t.tokens, Token{
			Type:  TokenOperator,
			Value: upperValue,
		})
		return
	}

	// AND, OR, NOT with space before '(' or no '(' → Operator
	if upperValue == "AND" || upperValue == "OR" || upperValue == "NOT" {
		t.tokens = append(t.tokens, Token{
			Type:  TokenOperator,
			Value: upperValue,
		})
		return
	}

	// For other identifiers, check if it's a function
	if hasParenthesisAfterSpace {
		t.skipWhitespace() // consume whitespace
		t.tokens = append(t.tokens, Token{
			Type:  TokenFunction,
			Value: upperValue,
		})
		return
	}

	// Everything else is a variable/identifier
	t.tokens = append(t.tokens, Token{
		Type:  TokenVariable,
		Value: value,
	})
}

func (t *Tokenizer) readOperator() bool {
	ch := t.input[t.position]

	if t.position+1 < len(t.input) {
		twoChar := string(t.input[t.position : t.position+2])
		switch twoChar {
		case ">=", "<=", "!=", "<>":
			t.tokens = append(t.tokens, Token{Type: TokenOperator, Value: twoChar})
			t.position += 2
			return true
		case "IS":
			t.tokens = append(t.tokens, Token{Type: TokenOperator, Value: "IS"})
			t.position += 2
			return true
		}
	}

	switch ch {
	case '+', '-', '*', '/', '%', '^', '>', '<', '=':
		t.tokens = append(t.tokens, Token{Type: TokenOperator, Value: string(ch)})
		t.position++
		return true
	case '(':
		t.tokens = append(t.tokens, Token{Type: TokenLeftParen, Value: "("})
		t.position++
		return true
	case ')':
		t.tokens = append(t.tokens, Token{Type: TokenRightParen, Value: ")"})
		t.position++
		return true
	case ',':
		t.tokens = append(t.tokens, Token{Type: TokenComma, Value: ","})
		t.position++
		return true
	}

	return false
}

// ============================================================================
// PARSER - Fixed to handle IN operator correctly
// ============================================================================

type Parser struct {
	tokens   []Token
	position int
}

func NewParser(input string) *Parser {
	tokenizer := NewTokenizer(input)
	tokens := tokenizer.Tokenize()
	return &Parser{tokens: tokens, position: 0}
}

func (p *Parser) Parse() Expression {
	expr := p.parseExpression()
	if p.position < len(p.tokens)-1 {
		remaining := []Token{}
		for i := p.position; i < len(p.tokens); i++ {
			remaining = append(remaining, p.tokens[i])
		}
		panic(fmt.Sprintf("Unexpected token at position %d: %v. Remaining tokens: %v", p.position, p.tokens[p.position], remaining))
	}
	return expr
}

func (p *Parser) parseExpression() Expression {
	return p.parseLogicalOr()
}

func (p *Parser) parseLogicalOr() Expression {
	left := p.parseLogicalAnd()

	for p.position < len(p.tokens) && p.tokens[p.position].Type == TokenOperator && p.tokens[p.position].Value == "OR" {
		p.position++
		right := p.parseLogicalAnd()
		left = NewOr(left, right)
	}

	return left
}

func (p *Parser) parseLogicalAnd() Expression {
	left := p.parseComparison()

	for p.position < len(p.tokens) && p.tokens[p.position].Type == TokenOperator && p.tokens[p.position].Value == "AND" {
		p.position++
		right := p.parseComparison()
		left = NewAnd(left, right)
	}

	return left
}

func (p *Parser) parseComparison() Expression {
	left := p.parseAddSub()

	// Loop to handle multiple comparison operators
	for p.position < len(p.tokens) {
		token := p.tokens[p.position]

		// Check if it's an operator token
		if token.Type != TokenOperator {
			break
		}

		op := token.Value

		// Check if it's a comparison operator we handle
		switch op {
		case "=", "!=", "<>", ">", ">=", "<", "<=":
			p.position++
			right := p.parseAddSub()
			switch op {
			case "=":
				left = NewEqual(left, right)
			case "!=", "<>":
				left = NewNotEqual(left, right)
			case ">":
				left = NewGreaterThan(left, right)
			case ">=":
				left = NewGreaterThanOrEqual(left, right)
			case "<":
				left = NewLessThan(left, right)
			case "<=":
				left = NewLessThanOrEqual(left, right)
			}
		case "IN":
			p.position++
			right := p.parseInOperand()
			left = NewIn(left, right)
		case "IS":
			p.position++
			// Handle IS NULL or IS NOT NULL
			if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenOperator && p.tokens[p.position].Value == "NOT" {
				p.position++
				if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenString && p.tokens[p.position].Value == "NULL" {
					p.position++
					left = NewIsNotNull(left)
				} else {
					panic("Expected NULL after IS NOT")
				}
			} else if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenString && p.tokens[p.position].Value == "NULL" {
				p.position++
				left = NewIsNull(left)
			} else {
				panic("Expected NULL after IS")
			}
		case "AND", "OR", "NOT":
			// These are logical operators, not comparison operators
			// Let the caller handle them
			return left
		default:
			// Unknown operator at comparison level
			return left
		}
	}

	return left
}

func (p *Parser) parseInOperand() Expression {
	// IN can have: IN ($var) or IN (val1, val2, val3)
	if p.position >= len(p.tokens) {
		panic("Expected operand after IN")
	}

	// If it's a variable (like $2), return it directly
	if p.tokens[p.position].Type == TokenVariable {
		token := p.tokens[p.position]
		p.position++
		return NewVariable(token.Value)
	}

	// If it's a parenthesized list
	if p.tokens[p.position].Type == TokenLeftParen {
		p.position++

		// Check if it's a single variable inside parens: IN ($2)
		if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenVariable {
			varToken := p.tokens[p.position]
			p.position++
			if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenRightParen {
				p.position++
				return NewVariable(varToken.Value)
			}
			// If there's more after the variable, treat it as a list
			p.position-- // backtrack
		}

		// Parse as array literal: (1, 2, 3, 4)
		values := []interface{}{}

		for {
			if p.position >= len(p.tokens) {
				panic("Unexpected end in IN list")
			}

			if p.tokens[p.position].Type == TokenRightParen {
				p.position++
				break
			}

			if p.tokens[p.position].Type == TokenNumber {
				num, _ := strconv.ParseFloat(p.tokens[p.position].Value, 64)
				values = append(values, num)
				p.position++
			} else if p.tokens[p.position].Type == TokenString {
				values = append(values, p.tokens[p.position].Value)
				p.position++
			} else {
				panic(fmt.Sprintf("Expected number or string in IN list, got %v", p.tokens[p.position]))
			}

			if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenComma {
				p.position++
			}
		}

		return NewConstant(values)
	}

	panic(fmt.Sprintf("Expected ( or variable after IN, got %v", p.tokens[p.position]))
}

func (p *Parser) parseAddSub() Expression {
	left := p.parseMulDiv()

	for p.position < len(p.tokens) && p.tokens[p.position].Type == TokenOperator {
		op := p.tokens[p.position].Value
		if op != "+" && op != "-" {
			break
		}
		p.position++
		right := p.parseMulDiv()
		if op == "+" {
			left = NewAdd(left, right)
		} else {
			left = NewSubtract(left, right)
		}
	}

	return left
}

func (p *Parser) parseMulDiv() Expression {
	left := p.parseUnary()

	for p.position < len(p.tokens) && p.tokens[p.position].Type == TokenOperator {
		op := p.tokens[p.position].Value
		if op != "*" && op != "/" && op != "%" {
			break
		}
		p.position++
		right := p.parseUnary()
		switch op {
		case "*":
			left = NewMultiply(left, right)
		case "/":
			left = NewDivide(left, right)
		case "%":
			left = NewModulo(left, right)
		}
	}

	return left
}

func (p *Parser) parseUnary() Expression {
	if p.position >= len(p.tokens) {
		panic("Unexpected end of input")
	}

	token := p.tokens[p.position]

	if token.Type == TokenOperator && token.Value == "NOT" {
		p.position++
		operand := p.parseUnary()
		return NewNot(operand)
	}

	if token.Type == TokenOperator && token.Value == "-" {
		p.position++
		operand := p.parseUnary()
		return NewNegate(operand)
	}

	return p.parsePrimary()
}

func (p *Parser) parsePrimary() Expression {
	if p.position >= len(p.tokens) {
		panic("Unexpected end of input")
	}

	token := p.tokens[p.position]

	if token.Type == TokenFunction {
		return p.parseFunction()
	}

	if token.Type == TokenLeftParen {
		p.position++
		expr := p.parseExpression()
		if p.position >= len(p.tokens) || p.tokens[p.position].Type != TokenRightParen {
			panic("Expected closing parenthesis")
		}
		p.position++
		return expr
	}

	if token.Type == TokenNumber {
		p.position++
		num, err := strconv.ParseFloat(token.Value, 64)
		if err != nil {
			panic(fmt.Sprintf("Invalid number: %s", token.Value))
		}
		return NewConstant(num)
	}

	if token.Type == TokenString {
		p.position++
		if token.Value == "NULL" {
			return NewConstant(nil)
		}
		return NewConstant(token.Value)
	}

	if token.Type == TokenVariable {
		p.position++
		return NewVariable(token.Value)
	}

	panic(fmt.Sprintf("Unexpected token: %v", token))
}

func (p *Parser) parseFunction() Expression {
	if p.position >= len(p.tokens) || p.tokens[p.position].Type != TokenFunction {
		panic("Expected function name")
	}

	funcName := p.tokens[p.position].Value
	p.position++

	if p.position >= len(p.tokens) || p.tokens[p.position].Type != TokenLeftParen {
		panic(fmt.Sprintf("Expected '(' after function name %s", funcName))
	}
	p.position++

	args := []Expression{}

	if p.position < len(p.tokens) && p.tokens[p.position].Type == TokenRightParen {
		p.position++
		return NewFunctionCall(funcName, args)
	}

	args = append(args, p.parseExpression())

	for p.position < len(p.tokens) && p.tokens[p.position].Type == TokenComma {
		p.position++
		args = append(args, p.parseExpression())
	}

	if p.position >= len(p.tokens) || p.tokens[p.position].Type != TokenRightParen {
		panic(fmt.Sprintf("Expected ')' after function arguments for %s", funcName))
	}
	p.position++

	return NewFunctionCall(funcName, args)
}

// ============================================================================
// MAIN - TEST CASES
// ============================================================================

func main() {
	fmt.Println("=== Expression Engine - Fixed Parser Tests ===")
	fmt.Println()

	testExcelFormula()
	testNestedFunctions()
	testComplexLogic()
	testSQLWhere()
	testAdvancedSQL()
	testMixedOperators()
	testNestedConditions()
	testMathOperations()
}

func testExcelFormula() {
	fmt.Println("--- Test 1: Excel Formula ---")

	formula := "IF(AND($1 > 100, OR($2 < 50, NOT($3 = 0))), SUM($4, $5) * 1.2, 0)"

	variables := map[string]interface{}{
		"$1": 150.0,
		"$2": 50.0,
		"$3": 5.0,
		"$4": 100.0,
		"$5": 200.0,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:   %s\n", formula)
	fmt.Printf("Parsed:    %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:    %v\n", result)
	fmt.Printf("Expected:  360 (because AND(true, OR(false, true)) = true, so SUM(100,200)*1.2 = 360)\n\n")
}

func testNestedFunctions() {
	fmt.Println("--- Test 2: Nested Functions ---")

	formula := "MAX(SUM($1, $2), AVG($3, $4, $5))"

	variables := map[string]interface{}{
		"$1": 50.0,
		"$2": 50.0,
		"$3": 100.0,
		"$4": 200.0,
		"$5": 300.0,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: 200 (MAX(100, 200) = 200)\n\n")
}

func testComplexLogic() {
	fmt.Println("--- Test 3: Complex Logic ---")

	formula := "IF(AND($status = 'ACTIVE', OR($tier = 'VIP', $revenue > 10000)), $price * 0.8, $price)"

	variables := map[string]interface{}{
		"$status":  "ACTIVE",
		"$tier":    "GOLD",
		"$revenue": 15000.0,
		"$price":   1000.0,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: 800 (status=ACTIVE AND revenue>10000, so 1000*0.8=800)\n\n")
}

func testSQLWhere() {
	fmt.Println("--- Test 4: SQL WHERE Clause ---")

	formula := "price > $1 AND customer_id IN ($2) AND (status = $3 OR deleted_at = NULL)"

	variables := map[string]interface{}{
		"$1":          150.0,
		"$2":          []interface{}{1.0, 2.0, 3.0, 4.0},
		"$3":          "ACTIVE",
		"price":       200.0,
		"customer_id": 2.0,
		"status":      "ACTIVE",
		"deleted_at":  nil,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: true\n")

	sqlVisitor := NewSQLCompilerVisitor()
	expr.Accept(sqlVisitor)
	fmt.Printf("SQL:      %s\n\n", sqlVisitor.Result())
}

func testAdvancedSQL() {
	fmt.Println("--- Test 5: Advanced SQL with Multiple Conditions ---")

	formula := "age >= $1 AND age <= $2 AND country IN ($3) AND (premium = $4 OR trial_days > $5)"

	variables := map[string]interface{}{
		"$1":         18.0,
		"$2":         65.0,
		"$3":         []interface{}{"US", "UK", "CA"},
		"$4":         true,
		"$5":         7.0,
		"age":        25.0,
		"country":    "US",
		"premium":    true,
		"trial_days": 0.0,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: true (age in range, country in list, premium=true)\n")

	sqlVisitor := NewSQLCompilerVisitor()
	expr.Accept(sqlVisitor)
	fmt.Printf("SQL:      %s\n\n", sqlVisitor.Result())
}

func testMixedOperators() {
	fmt.Println("--- Test 6: Mixed Arithmetic & Comparison ---")

	formula := "($price * (1 - $discount) + $shipping) >= $min_order AND $quantity > 0"

	variables := map[string]interface{}{
		"$price":     100.0,
		"$discount":  0.2,
		"$shipping":  10.0,
		"$min_order": 50.0,
		"$quantity":  5.0,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: true (100*0.8+10=90 >= 50 AND 5>0)\n\n")
}

func testNestedConditions() {
	fmt.Println("--- Test 7: Deeply Nested Conditions ---")

	formula := "IF(OR(AND($a > 0, $b > 0), AND($c > 0, $d > 0)), IF($sum > 100, $sum * 1.5, $sum * 1.2), 0)"

	variables := map[string]interface{}{
		"$a":   5.0,
		"$b":   10.0,
		"$c":   0.0,
		"$d":   0.0,
		"$sum": 120.0,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: 180 (OR(true, false)=true, 120>100, so 120*1.5=180)\n\n")
}

func testMathOperations() {
	fmt.Println("--- Test 8: Mathematical Functions ---")

	formula := "ROUND(ABS($value) * 1.15, 2) + CEIL($bonus) - FLOOR($penalty)"

	variables := map[string]interface{}{
		"$value":   -85.5,
		"$bonus":   12.3,
		"$penalty": 5.9,
	}

	parser := NewParser(formula)
	expr := parser.Parse()

	toStringVisitor := NewToStringVisitor()
	expr.Accept(toStringVisitor)
	fmt.Printf("Formula:  %s\n", formula)
	fmt.Printf("Parsed:   %s\n", toStringVisitor.Result())

	evalVisitor := NewEvaluateVisitor(variables)
	result := expr.Accept(evalVisitor)
	fmt.Printf("Result:   %v\n", result)
	fmt.Printf("Expected: 106.33 (ROUND(85.5*1.15,2)=98.33, +CEIL(12.3)=13, -FLOOR(5.9)=5 → 98.33+13-5=106.33)\n\n")
}
