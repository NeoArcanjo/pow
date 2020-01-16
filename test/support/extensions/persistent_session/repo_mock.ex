defmodule PowPersistentSession.Test.RepoMock do
  @moduledoc false
  alias Pow.Ecto.Schema.TokenSacdigital
  alias PowPersistentSession.Test.Users.User

  def get_by(User, [id: 1], _opts), do: %User{id: 1}
  def get_by(User, [id: -1], _opts), do: nil

  def get_by(User, [email: "test@example.com"], _opts),
    do: %User{id: 1, token_sacdigital_hash: TokenSacdigital.pbkdf2_hash("secret1234")}
end
