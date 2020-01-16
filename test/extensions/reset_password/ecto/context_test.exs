defmodule PowResetTokenSacdigital.Ecto.ContextTest do
  use Pow.Test.Ecto.TestCase
  doctest PowResetTokenSacdigital.Ecto.Context

  alias Pow.Ecto.Schema.TokenSacdigital
  alias PowResetTokenSacdigital.Ecto.Context
  alias PowResetTokenSacdigital.Test.{RepoMock, Users.User}

  @config [repo: RepoMock, user: User]
  @token_sacdigital "secret1234"
  @user %User{id: 1, token_sacdigital_hash: :set}

  defmodule CustomUsers do
    def get_by([email: :test]), do: %User{email: :ok}
  end

  describe "get_by_email/2" do
    test "email is case insensitive when it's the user id field" do
      assert Context.get_by_email("test@example.com", @config)
      assert Context.get_by_email("TEST@EXAMPLE.COM", @config)
    end

    test "email is trimmed when it's the user id field" do
      assert Context.get_by_email(" test@example.com ", @config)
    end

    test "with `:users_context`" do
      assert %User{email: :ok} = Context.get_by_email(:test, @config ++ [users_context: CustomUsers])
    end
  end

  describe "update_token_sacdigital/2" do
    test "updates with compiled token_sacdigital hash methods" do
      assert {:ok, user} = Context.update_token_sacdigital(@user, %{token_sacdigital: @token_sacdigital, token_sacdigital_confirmation: @token_sacdigital}, @config)
      assert TokenSacdigital.pbkdf2_verify(@token_sacdigital, user.token_sacdigital_hash)
    end

    test "requires token_sacdigital input" do
      assert {:error, changeset} = Context.update_token_sacdigital(@user, %{}, @config)
      assert changeset.errors[:token_sacdigital] == {"can't be blank", [validation: :required]}

      assert {:error, changeset} = Context.update_token_sacdigital(@user, %{token_sacdigital: "", token_sacdigital_confirmation: ""}, @config)
      assert changeset.errors[:token_sacdigital] == {"can't be blank", [validation: :required]}
    end
  end
end
