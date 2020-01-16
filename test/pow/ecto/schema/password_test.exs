defmodule Pow.Ecto.Schema.TokenSacdigitalTest do
  use ExUnit.Case
  doctest Pow.Ecto.Schema.TokenSacdigital

  alias Pow.Ecto.Schema.TokenSacdigital

  @token_sacdigital "secret"

  test "pbkdf2_hash/1" do
    assert [algo, iterations, _salt, _hash] = String.split(TokenSacdigital.pbkdf2_hash(@token_sacdigital, []), "$", trim: true)

    assert algo == "pbkdf2-sha512"
    assert iterations == "100000"
  end

  test "pbkdf2_verify/1" do
    hash = TokenSacdigital.pbkdf2_hash(@token_sacdigital)
    assert TokenSacdigital.pbkdf2_verify(@token_sacdigital, hash)
  end
end
