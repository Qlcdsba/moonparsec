// Numeric and boolean parsers

pub fn digit() -> Parser[Char] {
  satisfy(fn(c) { c >= '0' && c <= '9' })
}

pub fn alpha() -> Parser[Char] {
  Parser::new(fn(state) {
    if state.offset < state.input.length() {
      let c = get_char(state.input, state.offset)
      if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') {
        let next_s = State::{
          input: state.input,
          offset: state.offset + 1,
          line: if c == '\n' { state.line + 1 } else { state.line },
          col: if c == '\n' { 1 } else { state.col + 1 }
        }
        Ok((c, next_s))
      } else {
        let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
        Err(ParseError::{ pos, detail: AlphaExpected })
      }
    } else {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      Err(ParseError::{ pos, detail: EOF })
    }
  })
}

pub fn bool() -> Parser[Bool] {
  let parse_true = tag("true").map(fn(_) { true })
  let parse_false = tag("false").map(fn(_) { false })
  parse_true.or(parse_false)
}

pub fn int() -> Parser[Int] {
  Parser::new(fn(state) {
    if state.offset >= state.input.length() {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      return Err(ParseError::{ pos, detail: EOF })
    }
    let mut is_neg = false
    let mut current_offset = state.offset
    
    let c = get_char(state.input, current_offset)
    if c == '-' {
      is_neg = true
      current_offset = current_offset + 1
    } else if c == '+' {
      current_offset = current_offset + 1
    }
    
    if current_offset >= state.input.length() {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      return Err(ParseError::{ pos, detail: IntExpected })
    }
    
    let mut val = 0
    let mut has_digits = false
    
    while current_offset < state.input.length() {
      let digit_char = get_char(state.input, current_offset)
      if digit_char >= '0' && digit_char <= '9' {
        has_digits = true
        val = val * 10 + (digit_char.to_int() - '0'.to_int())
        current_offset = current_offset + 1
      } else {
        break
      }
    }
    
    if !has_digits {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      return Err(ParseError::{ pos, detail: IntExpected })
    }
    
    let final_val = if is_neg { -val } else { val }
    
    let mut next_line = state.line
    let mut next_col = state.col
    let mut k = state.offset
    while k < current_offset {
      let ch = get_char(state.input, k)
      if ch == '\n' {
        next_line = next_line + 1
        next_col = 1
      } else {
        next_col = next_col + 1
      }
      k = k + 1
    }
    
    let next_s = State::{
      input: state.input,
      offset: current_offset,
      line: next_line,
      col: next_col
    }
    Ok((final_val, next_s))
  })
}

pub fn float() -> Parser[Double] {
  Parser::new(fn(state) {
    if state.offset >= state.input.length() {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      return Err(ParseError::{ pos, detail: EOF })
    }
    let mut current_offset = state.offset
    let c = get_char(state.input, current_offset)
    if c == '-' || c == '+' {
      current_offset = current_offset + 1
    }
    
    let mut has_digits = false
    while current_offset < state.input.length() {
      let ch = get_char(state.input, current_offset)
      if ch >= '0' && ch <= '9' {
        has_digits = true
        current_offset = current_offset + 1
      } else {
        break
      }
    }
    
    if current_offset < state.input.length() {
      let ch = get_char(state.input, current_offset)
      if ch == '.' {
        current_offset = current_offset + 1
        let mut has_frac_digits = false
        while current_offset < state.input.length() {
          let ch2 = get_char(state.input, current_offset)
          if ch2 >= '0' && ch2 <= '9' {
            has_frac_digits = true
            current_offset = current_offset + 1
          } else {
            break
          }
        }
        if !has_frac_digits {
          let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
          return Err(ParseError::{ pos, detail: DigitExpected })
        }
      }
    }
    
    if current_offset < state.input.length() {
      let ch = get_char(state.input, current_offset)
      if ch == 'e' || ch == 'E' {
        current_offset = current_offset + 1
        if current_offset < state.input.length() {
          let ch2 = get_char(state.input, current_offset)
          if ch2 == '-' || ch2 == '+' {
            current_offset = current_offset + 1
          }
        }
        let mut has_exp_digits = false
        while current_offset < state.input.length() {
          let ch2 = get_char(state.input, current_offset)
          if ch2 >= '0' && ch2 <= '9' {
            has_exp_digits = true
            current_offset = current_offset + 1
          } else {
            break
          }
        }
        if !has_exp_digits {
          let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
          return Err(ParseError::{ pos, detail: DigitExpected })
        }
      }
    }
    
    if !has_digits {
      let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
      return Err(ParseError::{ pos, detail: DigitExpected })
    }
    
    let mut num_str = ""
    let mut i = state.offset
    while i < current_offset {
      num_str = num_str + get_char(state.input, i).to_string()
      i = i + 1
    }
    
    try {
      let val = @string.parse_double(num_str)
      let mut next_line = state.line
      let mut next_col = state.col
      let mut k = state.offset
      while k < current_offset {
        let ch = get_char(state.input, k)
        if ch == '\n' {
          next_line = next_line + 1
          next_col = 1
        } else {
          next_col = next_col + 1
        }
        k = k + 1
      }
      let next_s = State::{
        input: state.input,
        offset: current_offset,
        line: next_line,
        col: next_col
      }
      Ok((val, next_s))
    } catch {
      _ => {
        let pos = Position::{ line: state.line, col: state.col, offset: state.offset }
        Err(ParseError::{ pos, detail: FloatExpected })
      }
    }
  })
}
