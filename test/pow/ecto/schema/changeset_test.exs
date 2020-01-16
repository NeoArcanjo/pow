defmodule Pow.Ecto.Schema.ChangesetTest do
  use Pow.Test.Ecto.TestCase
  doctest Pow.Ecto.Schema.Changeset

  alias Pow.Ecto.Schema.{Changeset, TokenSacdigital}
  alias Pow.Test.Ecto.{Repo, Users.User, Users.UsernameUser}

  describe "User.changeset/2" do
    @valid_params %{
      "email" => "john.doe@example.com",
      "token_sacdigital" => "secret1234",
      "token_sacdigital_confirmation" => "secret1234",
      "custom" => "custom"
    }
    @valid_params_username %{
      "username" => "john.doe",
      "token_sacdigital" => "secret1234",
      "token_sacdigital_confirmation" => "secret1234"
    }

    test "requires user id" do
      changeset = User.changeset(%User{}, @valid_params)
      assert changeset.valid?

      changeset = User.changeset(%User{}, Map.delete(@valid_params, "email"))
      refute changeset.valid?
      assert changeset.errors[:email] == {"can't be blank", [validation: :required]}

      changeset = User.changeset(%User{email: "john.doe@example.com"}, %{email: nil})
      refute changeset.valid?
      assert changeset.errors[:email] == {"can't be blank", [validation: :required]}

      changeset = UsernameUser.changeset(%UsernameUser{}, Map.delete(@valid_params_username, "username"))
      refute changeset.valid?
      assert changeset.errors[:username] == {"can't be blank", [validation: :required]}

      changeset = UsernameUser.changeset(%UsernameUser{}, @valid_params_username)
      assert changeset.valid?
    end

    test "validates user id as email" do
      changeset = User.changeset(%User{}, Map.put(@valid_params, "email", "invalid"))
      refute changeset.valid?
      assert changeset.errors[:email] == {"has invalid format", [validation: :email_format, reason: "invalid format"]}
      assert changeset.validations[:email] == {:email_format, &Pow.Ecto.Schema.Changeset.validate_email/1}

      changeset = User.changeset(%User{}, @valid_params)
      assert changeset.valid?
    end

    test "can validate with custom e-mail validator" do
      config    = [email_validator: &{:error, "custom message #{&1}"}]
      changeset = Changeset.user_id_field_changeset(%User{}, @valid_params, config)

      refute changeset.valid?
      assert changeset.errors[:email] == {"has invalid format", [validation: :email_format, reason: "custom message john.doe@example.com"]}
      assert changeset.validations[:email] == {:email_format, config[:email_validator]}

      config    = [email_validator: fn _email -> :ok end]
      changeset = Changeset.user_id_field_changeset(%User{}, @valid_params, config)

      assert changeset.valid?
    end

    test "uses case insensitive value for user id" do
      changeset = User.changeset(%User{}, Map.put(@valid_params, "email", "Test@EXAMPLE.com"))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :email) == "test@example.com"

      changeset = UsernameUser.changeset(%UsernameUser{}, Map.put(@valid_params, "username", "uSerName"))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :username) == "username"
    end

    test "trims value for user id" do
      changeset = User.changeset(%User{}, Map.put(@valid_params, "email", " test@example.com "))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :email) == "test@example.com"

      changeset = UsernameUser.changeset(%UsernameUser{}, Map.put(@valid_params, "username", " username "))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :username) == "username"
    end

    test "requires unique user id" do
      {:ok, _user} =
        %User{}
        |> Ecto.Changeset.cast(@valid_params, [:email])
        |> Repo.insert()

      assert {:error, changeset} =
        %User{}
        |> User.changeset(@valid_params)
        |> Repo.insert()
      assert changeset.errors[:email] == {"has already been taken", constraint: :unique, constraint_name: "users_email_index"}

      {:ok, _user} =
        %UsernameUser{}
        |> Ecto.Changeset.cast(@valid_params_username, [:username])
        |> Repo.insert()

      assert {:error, changeset} =
        %UsernameUser{}
        |> UsernameUser.changeset(@valid_params_username)
        |> Repo.insert()
      assert changeset.errors[:username] == {"has already been taken", constraint: :unique, constraint_name: "users_username_index"}
    end

    test "requires token_sacdigital when token_sacdigital_hash is nil" do
      params = Map.delete(@valid_params, "token_sacdigital")
      changeset = User.changeset(%User{}, params)

      refute changeset.valid?
      assert changeset.errors[:token_sacdigital] == {"can't be blank", [validation: :required]}

      token_sacdigital = "secret"
      user = %User{token_sacdigital_hash: TokenSacdigital.pbkdf2_hash(token_sacdigital)}
      params = Map.put(@valid_params, "current_token_sacdigital", token_sacdigital)
      changeset = User.changeset(user, params)

      assert changeset.valid?
    end

    test "validates length of token_sacdigital" do
      changeset = User.changeset(%User{}, Map.put(@valid_params, "token_sacdigital", Enum.join(1..7)))

      refute changeset.valid?
      assert changeset.errors[:token_sacdigital] == {"should be at least %{count} character(s)", [count: 8, validation: :length, kind: :min, type: :string]}

      changeset = User.changeset(%User{}, Map.put(@valid_params, "token_sacdigital", Enum.join(1..4096)))
      refute changeset.valid?
      assert changeset.errors[:token_sacdigital] == {"should be at most %{count} character(s)", [count: 4096, validation: :length, kind: :max, type: :string]}
    end

    test "can use custom length requirements for token_sacdigital" do
      config = [token_sacdigital_min_length: 5, token_sacdigital_max_length: 10]

      changeset = Changeset.token_sacdigital_changeset(%User{}, %{"token_sacdigital" => "abcd"}, config)
      refute changeset.valid?
      assert changeset.errors[:token_sacdigital] == {"should be at least %{count} character(s)", [count: 5, validation: :length, kind: :min, type: :string]}

      changeset = Changeset.token_sacdigital_changeset(%User{}, %{"token_sacdigital" => "abcdefghijk"}, config)
      refute changeset.valid?
      assert changeset.errors[:token_sacdigital] == {"should be at most %{count} character(s)", [count: 10, validation: :length, kind: :max, type: :string]}
    end

    test "can confirm and hash token_sacdigital" do
      changeset = User.changeset(%User{}, Map.put(@valid_params, "token_sacdigital_confirmation", "invalid"))

      refute changeset.valid?
      assert changeset.errors[:token_sacdigital_confirmation] == {"does not match confirmation", [validation: :confirmation]}
      refute changeset.changes[:token_sacdigital_hash]

      changeset = User.changeset(%User{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes[:token_sacdigital_hash]
      assert TokenSacdigital.pbkdf2_verify("secret1234", changeset.changes[:token_sacdigital_hash])
    end

    # TODO: Remove by 1.1.0
    test "handle `confirm_token_sacdigital` conversion" do
      params =
        @valid_params
        |> Map.delete("token_sacdigital_confirmation")
        |> Map.put("confirm_token_sacdigital", "secret1234")
      changeset = User.changeset(%User{}, params)

      assert changeset.valid?

      params    = Map.put(params, "confirm_token_sacdigital", "invalid")
      changeset = User.changeset(%User{}, params)

      refute changeset.valid?
      assert changeset.errors[:confirm_token_sacdigital] == {"does not match confirmation", [validation: :confirmation]}
      refute changeset.errors[:token_sacdigital_confirmation]
    end

    test "can use custom token_sacdigital hash methods" do
      token_sacdigital_hash = &(&1 <> "123")
      token_sacdigital_verify = &(&1 == &2 <> "123")
      config = [token_sacdigital_hash_methods: {token_sacdigital_hash, token_sacdigital_verify}]

      changeset = Changeset.token_sacdigital_changeset(%User{}, @valid_params, config)

      assert changeset.valid?
      assert changeset.changes[:token_sacdigital_hash] == "secret1234123"
    end

    test "requires current token_sacdigital when token_sacdigital_hash exists" do
      user = %User{token_sacdigital_hash: TokenSacdigital.pbkdf2_hash("secret1234")}

      changeset = User.changeset(%User{}, @valid_params)
      assert changeset.valid?

      changeset = User.changeset(user, @valid_params)
      refute changeset.valid?
      assert changeset.errors[:current_token_sacdigital] == {"can't be blank", [validation: :required]}

      changeset = User.changeset(%{user | current_token_sacdigital: "secret1234"}, @valid_params)
      refute changeset.valid?
      assert changeset.errors[:current_token_sacdigital] == {"can't be blank", [validation: :required]}

      changeset = User.changeset(user, Map.put(@valid_params, "current_token_sacdigital", "invalid"))
      refute changeset.valid?
      assert changeset.errors[:current_token_sacdigital] == {"is invalid", [validation: :verify_token_sacdigital]}
      assert changeset.validations[:current_token_sacdigital] == {:verify_token_sacdigital, []}

      changeset = User.changeset(user, Map.put(@valid_params, "current_token_sacdigital", "secret1234"))
      assert changeset.valid?
    end

    test "as `use User`" do
      changeset = User.changeset(%User{}, @valid_params)
      assert changeset.valid?
      assert changeset.changes[:email]
      assert changeset.changes[:custom]
    end
  end

  describe "User.verify_token_sacdigital/2" do
    test "verifies" do
      refute User.verify_token_sacdigital(%User{}, "secret1234")

      token_sacdigital_hash = TokenSacdigital.pbkdf2_hash("secret1234")
      refute User.verify_token_sacdigital(%User{token_sacdigital_hash: token_sacdigital_hash}, "invalid")
      assert User.verify_token_sacdigital(%User{token_sacdigital_hash: token_sacdigital_hash}, "secret1234")
    end

    test "prevents timing attacks" do
      config = [
        token_sacdigital_hash_methods: {
          fn token_sacdigital ->
            send(self(), {:token_sacdigital_hash, token_sacdigital})

            ""
          end,
          fn token_sacdigital, token_sacdigital_hash ->
            send(self(), {:token_sacdigital_verify, token_sacdigital, token_sacdigital_hash})

            false
          end
        }
      ]

      refute Changeset.verify_token_sacdigital(%User{token_sacdigital_hash: nil}, "secret1234", config)
      assert_received {:token_sacdigital_hash, ""}

      refute Changeset.verify_token_sacdigital(%User{token_sacdigital_hash: "hash"}, "secret1234", config)
      assert_received {:token_sacdigital_verify, "secret1234", "hash"}
    end
  end

  test "validate_email/1" do
    # Format
    assert Changeset.validate_email("simple@example.com") == :ok
    assert Changeset.validate_email("very.common@example.com") == :ok
    assert Changeset.validate_email("disposable.style.email.with+symbol@example.com") == :ok
    assert Changeset.validate_email("other.email-with-hyphen@example.com") == :ok
    assert Changeset.validate_email("fully-qualified-domain@example.com") == :ok
    assert Changeset.validate_email("x@example.com") == :ok
    assert Changeset.validate_email("example-indeed@strange-example.com") == :ok
    assert Changeset.validate_email("admin@mailserver1") == :ok
    assert Changeset.validate_email("example@s.example") == :ok
    assert Changeset.validate_email("\" \"@example.org") == :ok
    assert Changeset.validate_email("\"john..doe\"@example.org") == :ok

    assert Changeset.validate_email("Abc.example.com") == {:error, "invalid format"}
    assert Changeset.validate_email("A@b@c@example.com") == {:error, "invalid characters in local-part"}
    assert Changeset.validate_email("a\"b(c)d,e:f;g<h>i[j\\k]l@example.com") == {:error, "invalid characters in local-part"}
    assert Changeset.validate_email("just\"not\"right@example.com") == {:error, "invalid characters in local-part"}
    assert Changeset.validate_email("this is\"not\\allowed@example.com") == {:error, "invalid characters in local-part"}
    assert Changeset.validate_email("this\\ still\\\"not\\\\allowed@example.com") == {:error, "invalid characters in local-part"}
    assert Changeset.validate_email("1234567890123456789012345678901234567890123456789012345678901234+x@example.com") == {:error, "local-part too long"}

    # Unicode
    assert Changeset.validate_email("Pelé@example.com") == :ok
    assert Changeset.validate_email("δοκιμή@παράδειγμα.δοκιμή") == :ok
    assert Changeset.validate_email("我買@屋企.香港") == :ok
    assert Changeset.validate_email("二ノ宮@黒川.日本") == :ok
    assert Changeset.validate_email("медведь@с-балалайкой.рф") == :ok

    # All error cases
    assert Changeset.validate_email("john..doe@example.com") == {:error, "consective dots in local-part"}
    assert Changeset.validate_email("john.doe@#{String.duplicate("x", 256)}") == {:error, "domain too long"}
    assert Changeset.validate_email("john.doe@-example.com") == {:error, "domain begins with hyphen"}
    assert Changeset.validate_email("john.doe@example-") == {:error, "domain ends with hyphen"}
    assert Changeset.validate_email("john.doe@invaliddomain$") == {:error, "invalid characters in domain"}
  end
end
