# moonwat

A high-performance, type-safe, and zero-dependency **Parser Combinator Library** for MoonBit.

`moonwat` enables developers to build robust, type-safe parsers for complex text formats (e.g., JSON, CSV, configuration languages, or DSLs) by combining small, easily testable parser primitives.

---

## Features

- **Type-Safe & Declarative**: Build parsers visually and logically using monadic and applicative combinators.
- **Efficient Parsing**: Uses cursor-offset state passing to eliminate unnecessary string allocations and copy operations.
- **Position & Span Tracking**: Automatically tracks the exact line, column, and character offset, enabling accurate source code tracking.
- **Rich Error Diagnosis**: Generates beautiful compiler-like diagnostic messages with visual caret (`^`) pointers pointing directly to the error context.
- **RFC-Compliant Examples**: Includes a complete RFC 4180 compliant CSV parser and a fully featured JSON parser built entirely on top of the library.

---

## Quick Start

The following example defines a parser for coordinates of the form `(12, -34)` and runs it:

```moonbit
// A parser that parses "(12, -34)" into a tuple (Int, Int)
fn parse_coordinate() -> Parser[(Int, Int)] {
  let comma_sep = char(',')
  let number = int()
  
  // parse "("
  char('(').preceded(
    // parse X coordinate
    number.terminated(comma_sep).and_then(fn(x) {
      // parse Y coordinate and ")"
      number.terminated(char(')')).map(fn(y) {
        (x, y)
      })
    })
  )
}

fn test_parse() {
  let p = parse_coordinate()
  let state = State::{ input: "(12,-34)", offset: 0, line: 1, col: 1 }
  match p.parse(state) {
    Ok(((x, y), _next_state)) => println("Parsed coordinate: \{x}, \{y}")
    Err(err) => println(err.format(state.input))
  }
}
```

---

## Architecture & Core Types

### 1. Position & Span Tracking
`Position` keeps track of the logical line, column, and raw byte offset in the input. `Span` bounds the start and end positions of a successfully parsed node.

```moonbit
pub struct Position {
  line : Int
  col : Int
  offset : Int
}

pub struct Span {
  start : Position
  end : Position
}
```

### 2. State & Parsing Result
The parser state holds the source input and current cursor information:

```moonbit
pub struct State {
  input : String
  offset : Int
  line : Int
  col : Int
}
```

A parser `Parser[O]` is a wrapper around a state-transformation function:
```moonbit
pub struct Parser[O] {
  f : (State) -> Result[(O, State), ParseError]
}
```

---

## API Reference

### Monad Primitives
- `Parser::pure(val)`: Creates a parser that succeeds immediately returning `val` without consuming input.
- `Parser::fail(detail)`: Creates a parser that fails immediately with the specified error detail.

### Core Combinators
- `p.map(f)`: Transforms the successful output of `p` using function `f`.
- `p.and_then(f)`: Sequences parser `p` and another parser returned by function `f`.
- `p.or(other)`: Tries `p`. If it fails, backtracks and tries `other`.
- `p.optional()`: Parses `p` optionally, returning `Some(val)` or `None`.
- `p.many0()`: Parses zero or more occurrences of `p`.
- `p.many1()`: Parses one or more occurrences of `p`.
- `p.span()`: Wraps `p` to return both its output and the `Span` of input consumed.

### Structural Combinators
- `preceded(prefix, p)`: Parses `prefix` then `p`, returning the result of `p`.
- `terminated(p, suffix)`: Parses `p` then `suffix`, returning the result of `p`.
- `delimited(left, p, right)`: Parses `left`, `p`, and `right`, returning only the result of `p`.
- `p.separated_list(sep)`: Parses zero or more occurrences of `p` separated by `sep`.
- `p.separated_list1(sep)`: Parses one or more occurrences of `p` separated by `sep`.

### Text Matching Primitives
- `any_char()`: Consumes and returns any single character.
- `satisfy(pred)`: Consumes a character if it satisfies a predicate `(Char) -> Bool`.
- `char(expected)`: Matches a specific character.
- `tag(expected)`: Matches a specific literal string.

### Numeric & Boolean Parsers
- `digit()`: Matches a digit `0`..`9`.
- `alpha()`: Matches an alphabetic character `a`..`z` or `A`..`Z`.
- `bool()`: Matches `"true"` or `"false"`.
- `int()`: Matches an integer, e.g., `123`, `-456`.
- `float()`: Matches a floating point number, e.g., `123.45`, `-0.012`, `1e-5`.

---

## Diagnostic Error Reporting

`moonwat` provides compiler-grade error reporting out of the box. Using `ParseError::format(self, input)` yields formatted diagnostic errors:

```
Parse error at line 1, col 5:
  (12a,-34)
      ^ -- DigitExpected
```

---

## Verification & Testing

To run the whitebox test suite, execute:
```bash
moon test
```