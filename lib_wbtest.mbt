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
  inspect(p.parse(s4), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=IntExpected))")
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

test "parser span" {
  let p = tag("hello").span()
  let s = State::{ input: "hello world", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok(((hello, Span(start=Position(line=1, col=1, offset=0), end=Position(line=1, col=6, offset=5))), State(offset=5, line=1, col=6)))")
}

test "parser error format" {
  let p = tag("hello")
  let s = State::{ input: "world", offset: 0, line: 1, col: 1 }
  match p.parse(s) {
    Ok(_) => fail("should fail")
    Err(err) => {
      let formatted = err.format(s.input)
      inspect(formatted, content=(
        #|Parse error at line 1, col 1:
        #|  world
        #|  ^ -- TagExpected("hello")
      ))
    }
  }
}

test "parser float invalid" {
  let p = float()
  let s = State::{ input: "123.", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=DigitExpected))")
  
  let s2 = State::{ input: "1e", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Err(ParseError(pos=Position(line=1, col=1, offset=0), detail=DigitExpected))")
}

test "parser tag with newlines" {
  let p = tag("a\nb\nc")
  let s = State::{ input: "a\nb\ncd", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok((a\nb\nc, State(offset=5, line=3, col=2)))")
}

test "parser separated_list empty and trailing" {
  let p = char('a').separated_list(char(','))
  let s1 = State::{ input: "", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s1), content="Ok(([], State(offset=0, line=1, col=1)))")
  
  let s2 = State::{ input: "a,a,a,", offset: 0, line: 1, col: 1 }
  inspect(p.parse(s2), content="Ok(([a, a, a], State(offset=5, line=1, col=6)))")
}

test "parser csv basic" {
  let p = csv_document()
  let input = "name,age,city\nAlice,30,New York\nBob,25,Paris"
  let s = State::{ input, offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok(([[name, age, city], [Alice, 30, New York], [Bob, 25, Paris]], State(offset=44, line=3, col=13)))")
}

test "parser csv quoted and escaped" {
  let p = csv_document()
  let input = "col1,col2\n\"hello, world\",\"he said: \"\"yes\"\"\""
  let s = State::{ input, offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok(([[col1, col2], [hello, world, he said: \"yes\"]], State(offset=43, line=2, col=34)))")
}

test "parser json basic" {
  let p = json_value()
  let input = " { \"key\": [true, null, 12.34] } "
  let s = State::{ input, offset: 0, line: 1, col: 1 }
  inspect(p.parse(s), content="Ok(({\"key\": [true, null, 12.34]}, State(offset=32, line=1, col=33)))")
}
