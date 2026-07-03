// Core types for moonparsec

pub struct Position {
  line : Int
  col : Int
  offset : Int
} derive(Debug, Eq)

pub struct State {
  input : String
  offset : Int
  line : Int
  col : Int
} derive(Debug, Eq)

pub enum ErrorDetail {
  CharExpected(Char)
  TagExpected(String)
  SatisfyFailed
  DigitExpected
  AlphaExpected
  IntExpected
  FloatExpected
  Custom(String)
  EOF
} derive(Debug, Eq)

pub struct ParseError {
  pos : Position
  detail : ErrorDetail
} derive(Debug, Eq)

pub struct Parser[O] {
  f : (State) -> Result[(O, State), ParseError]
}

pub fn[O] Parser::new(f : (State) -> Result[(O, State), ParseError]) -> Parser[O] {
  { f, }
}

pub fn[O] Parser::parse(self : Parser[O], state : State) -> Result[(O, State), ParseError] {
  (self.f)(state)
}

pub fn[O] Parser::pure(val : O) -> Parser[O] {
  Parser::new(fn(state) {
    Ok((val, state))
  })
}

pub fn[O] Parser::fail(detail : ErrorDetail) -> Parser[O] {
  Parser::new(fn(state) {
    let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
    Err(ParseError::{ pos, detail })
  })
}
