# frozen_string_literal: true

require 'oj'

Oj.default_options = {
  mode: :compat,
  symbol_keys: false,
  bigdecimal_as_decimal: true,
  time_format: :ruby
}
