// Core types for moonwat

pub struct Position {
  line : Int
  col : Int
  offset : Int
} derive(Eq)

pub impl Show for Position with fn output(self, logger) {
  logger.write_string("Position(line=\{self.line}, col=\{self.col}, offset=\{self.offset})")
}

pub struct Span {
  start : Position
  end : Position
} derive(Eq)

pub impl Show for Span with fn output(self, logger) {
  logger.write_string("Span(start=\{self.start}, end=\{self.end})")
}

pub struct State {
  input : String
  offset : Int
  line : Int
  col : Int
} derive(Eq)

pub impl Show for State with fn output(self, logger) {
  logger.write_string("State(offset=\{self.offset}, line=\{self.line}, col=\{self.col})")
}

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
} derive(Eq)

pub impl Show for ErrorDetail with fn output(self, logger) {
  match self {
    CharExpected(c) => logger.write_string("CharExpected('\{c}')")
    TagExpected(t) => logger.write_string("TagExpected(\"\{t}\")")
    SatisfyFailed => logger.write_string("SatisfyFailed")
    DigitExpected => logger.write_string("DigitExpected")
    AlphaExpected => logger.write_string("AlphaExpected")
    IntExpected => logger.write_string("IntExpected")
    FloatExpected => logger.write_string("FloatExpected")
    Custom(s) => logger.write_string("Custom(\"\{s}\")")
    EOF => logger.write_string("EOF")
  }
}

pub struct ParseError {
  pos : Position
  detail : ErrorDetail
} derive(Eq)

pub impl Show for ParseError with fn output(self, logger) {
  logger.write_string("ParseError(pos=\{self.pos}, detail=\{self.detail})")
}

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
