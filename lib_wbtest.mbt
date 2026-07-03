// Whitebox tests for core types and combinators

test "parser pure" {
  let p = Parser::pure(100)
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((100, State(offset=0, line=1, col=1)))")
}

test "parser fail" {
  let p : Parser[Int] = Parser::fail(Custom("error"))
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=Custom(\"error\")))")
}

test "parser map" {
  let p = Parser::pure(100).map(fn(x) { x * 2 })
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((200, State(offset=0, line=1, col=1)))")
}

test "parser and_then" {
  let p = Parser::pure(10).and_then(fn(x) {
    Parser::pure(x + 5)
  })
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((15, State(offset=0, line=1, col=1)))")
}

test "parser or choice success first" {
  let p1 = Parser::pure(1)
  let p2 = Parser::pure(2)
  let p = p1.or(p2)
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((1, State(offset=0, line=1, col=1)))")
}

test "parser or choice success second" {
  let p1 : Parser[Int] = Parser::fail(Custom("first failed"))
  let p2 = Parser::pure(2)
  let p = p1.or(p2)
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((2, State(offset=0, line=1, col=1)))")
}

fn char_a() -> Parser[Char] {
  Parser::new(fn(state) {
    if state.offset < state.input.length() && state.input[state.offset] == 'a' {
      let next_s = State::{
        input: state.input,
        offset: state.offset + 1,
        line: state.line,
        col: state.col + 1
      }
      Ok(('a', next_s))
    } else {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      Err(ParseError::{ pos, detail: CharExpected('a') })
    }
  })
}

test "parser optional" {
  let p = char_a().optional()
  let s = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((Some(a), State(offset=1, line=1, col=2)))")
  
  let s2 = State::{ input: "bbc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Ok((None, State(offset=0, line=1, col=1)))")
}

test "parser many0" {
  let p = char_a().many0()
  let s = State::{ input: "aaab", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok(([a, a, a], State(offset=3, line=1, col=4)))")
  
  let s2 = State::{ input: "bb", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Ok(([], State(offset=0, line=1, col=1)))")
}

test "parser many1" {
  let p = char_a().many1()
  let s = State::{ input: "aaab", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok(([a, a, a], State(offset=3, line=1, col=4)))")
  
  let s2 = State::{ input: "bb", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=CharExpected('a')))")
}

test "parser bool" {
  let p = bool()
  let s1 = State::{ input: "true", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s1), content="Ok((true, State(offset=4, line=1, col=5)))")
  
  let s2 = State::{ input: "false", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Ok((false, State(offset=5, line=1, col=6)))")
  
  let s3 = State::{ input: "flase", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s3), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=TagExpected(\"false\")))")
}

test "parser int" {
  let p = int()
  let s1 = State::{ input: "1234", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s1), content="Ok((1234, State(offset=4, line=1, col=5)))")
  
  let s2 = State::{ input: "-567", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Ok((-567, State(offset=4, line=1, col=5)))")
  
  let s3 = State::{ input: "+89", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s3), content="Ok((89, State(offset=3, line=1, col=4)))")
  
  let s4 = State::{ input: "abc", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s4), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=DigitExpected))")
}

test "parser float" {
  let p = float()
  let s1 = State::{ input: "123.45", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s1), content="Ok((123.45, State(offset=6, line=1, col=7)))")
  
  let s2 = State::{ input: "-0.012", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Ok((-0.012, State(offset=6, line=1, col=7)))")
  
  let s3 = State::{ input: "1e-5", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s3), content="Ok((0.00001, State(offset=4, line=1, col=5)))")
}
