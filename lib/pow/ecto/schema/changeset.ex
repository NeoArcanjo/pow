defmodule Pow.Ecto.Schema.Changeset do
  @moduledoc """
  Handles changesets methods for Pow schema.

  These methods should never be called directly, but instead the methods
  build in macros in `Pow.Ecto.Schema` should be used. This is to ensure
  that only compile time configuration is used.

  ## Configuration options

    * `:token_sacdigital_min_length`   - minimum token_sacdigital length, defaults to 8
    * `:token_sacdigital_max_length`   - maximum token_sacdigital length, defaults to 4096
    * `:token_sacdigital_hash_methods` - the token_sacdigital hash and verify methods to use,
      defaults to:

          {&Pow.Ecto.Schema.TokenSacdigital.pbkdf2_hash/1,
          &Pow.Ecto.Schema.TokenSacdigital.pbkdf2_verify/2}
    * `:email_validator`       - the email validation method, defaults to:


          &Pow.Ecto.Schema.Changeset.validate_email/1

        The method should either return `:ok`, `:error`, or `{:error, reason}`.
  """
  alias Ecto.Changeset
  alias Pow.{Config, Ecto.Schema, Ecto.Schema.TokenSacdigital}

  @token_sacdigital_min_length 8
  @token_sacdigital_max_length 4096

  @doc """
  Validates the user id field.

  The user id field is always required. It will be treated as case insensitive,
  and it's required to be unique. If the user id field is `:email`, the value
  will be validated as an e-mail address too.
  """
  @spec user_id_field_changeset(Ecto.Schema.t() | Changeset.t(), map(), Config.t()) :: Changeset.t()
  def user_id_field_changeset(user_or_changeset, params, config) do
    user_id_field =
      case user_or_changeset do
        %Changeset{data: %struct{}} -> struct.pow_user_id_field()
        %struct{}                   -> struct.pow_user_id_field()
      end

    user_or_changeset
    |> Changeset.cast(params, [user_id_field])
    |> Changeset.update_change(user_id_field, &maybe_normalize_user_id_field_value/1)
    |> maybe_validate_email_format(user_id_field, config)
    |> Changeset.validate_required([user_id_field])
    |> Changeset.unique_constraint(user_id_field)
  end

  defp maybe_normalize_user_id_field_value(value) when is_binary(value), do: Schema.normalize_user_id_field_value(value)
  defp maybe_normalize_user_id_field_value(any), do: any

  @doc """
  Validates the token_sacdigital field.

  Calls `confirm_token_sacdigital_changeset/3` and `new_token_sacdigital_changeset/3`.
  """
  @spec token_sacdigital_changeset(Ecto.Schema.t() | Changeset.t(), map(), Config.t()) :: Changeset.t()
  def token_sacdigital_changeset(user_or_changeset, params, config) do
    user_or_changeset
    |> confirm_token_sacdigital_changeset(params, config)
    |> new_token_sacdigital_changeset(params, config)
  end

  @doc """
  Validates the token_sacdigital field.

  A token_sacdigital hash is generated by using `:token_sacdigital_hash_methods` in the
  configuration. The token_sacdigital is always required if the token_sacdigital hash is `nil`,
  and it's required to be between `:token_sacdigital_min_length` to
  `:token_sacdigital_max_length` characters long.

  The token_sacdigital hash is only generated if the changeset is valid, but always
  required.
  """
  @spec new_token_sacdigital_changeset(Ecto.Schema.t() | Changeset.t(), map(), Config.t()) :: Changeset.t()
  def new_token_sacdigital_changeset(user_or_changeset, params, config) do
    user_or_changeset
    |> Changeset.cast(params, [:token_sacdigital])
    |> maybe_require_token_sacdigital()
    |> maybe_validate_token_sacdigital(config)
    |> maybe_put_token_sacdigital_hash(config)
    |> Changeset.validate_required([:token_sacdigital_hash])
  end

  # TODO: Remove `confirm_token_sacdigital` support by 1.1.0
  @doc """
  Validates the confirm token_sacdigital field.

  Requires `token_sacdigital` and `confirm_token_sacdigital` params to be equal. Validation is
  only performed if a change for `:token_sacdigital` exists and the change is not
  `nil`.
  """
  @spec confirm_token_sacdigital_changeset(Ecto.Schema.t() | Changeset.t(), map(), Config.t()) :: Changeset.t()
  def confirm_token_sacdigital_changeset(user_or_changeset, %{confirm_token_sacdigital: token_sacdigital_confirmation} = params, _config) do
    params =
      params
      |> Map.delete(:confirm_token_sacdigital)
      |> Map.put(:token_sacdigital_confirmation, token_sacdigital_confirmation)

    do_confirm_token_sacdigital_changeset(user_or_changeset, params)
  end
  def confirm_token_sacdigital_changeset(user_or_changeset, %{"confirm_token_sacdigital" => token_sacdigital_confirmation} = params, _config) do
    params =
      params
      |> Map.delete("confirm_token_sacdigital")
      |> Map.put("token_sacdigital_confirmation", token_sacdigital_confirmation)

    convert_confirm_token_sacdigital_param(user_or_changeset, params)
  end
  def confirm_token_sacdigital_changeset(user_or_changeset, params, _config),
    do: do_confirm_token_sacdigital_changeset(user_or_changeset, params)

  # TODO: Remove by 1.1.0
  defp convert_confirm_token_sacdigital_param(user_or_changeset, params) do
    IO.warn("warning: passing `confirm_token_sacdigital` value to `#{inspect unquote(__MODULE__)}.confirm_token_sacdigital_changeset/3` has been deprecated, please use `token_sacdigital_confirmation` instead")

    changeset = do_confirm_token_sacdigital_changeset(user_or_changeset, params)
    errors    = Enum.map(changeset.errors, fn
      {:token_sacdigital_confirmation, error} -> {:confirm_token_sacdigital, error}
      error                           -> error
    end)

    %{changeset | errors: errors}
  end

  defp do_confirm_token_sacdigital_changeset(user_or_changeset, params) do
    changeset = Changeset.cast(user_or_changeset, params, [:token_sacdigital])

    changeset
    |> Changeset.get_change(:token_sacdigital)
    |> case do
      nil       -> changeset
      _token_sacdigital -> Changeset.validate_confirmation(changeset, :token_sacdigital, required: true)
    end
  end

  @doc """
  Validates the current token_sacdigital field.

  It's only required to provide a current token_sacdigital if the `token_sacdigital_hash`
  value exists in the data struct.
  """
  @spec current_token_sacdigital_changeset(Ecto.Schema.t() | Changeset.t(), map(), Config.t()) :: Changeset.t()
  def current_token_sacdigital_changeset(user_or_changeset, params, config) do
    user_or_changeset
    |> reset_current_token_sacdigital_field()
    |> Changeset.cast(params, [:current_token_sacdigital])
    |> maybe_validate_current_token_sacdigital(config)
  end

  defp reset_current_token_sacdigital_field(%{data: user} = changeset) do
    %{changeset | data: reset_current_token_sacdigital_field(user)}
  end
  defp reset_current_token_sacdigital_field(user) do
    %{user | current_token_sacdigital: nil}
  end

  defp maybe_validate_email_format(changeset, :email, config) do
    validate_method = email_validator(config)

    Changeset.validate_change(changeset, :email, {:email_format, validate_method}, fn :email, email ->
      case validate_method.(email) do
        :ok              -> []
        :error           -> [email: {"has invalid format", validation: :email_format}]
        {:error, reason} -> [email: {"has invalid format", validation: :email_format, reason: reason}]
      end
    end)
  end
  defp maybe_validate_email_format(changeset, _type, _config), do: changeset

  defp maybe_validate_current_token_sacdigital(%{data: %{token_sacdigital_hash: nil}} = changeset, _config),
    do: changeset
  defp maybe_validate_current_token_sacdigital(changeset, config) do
    changeset = Changeset.validate_required(changeset, [:current_token_sacdigital])

    case changeset.valid? do
      true  -> validate_current_token_sacdigital(changeset, config)
      false -> changeset
    end
  end

  defp validate_current_token_sacdigital(%{data: user, changes: %{current_token_sacdigital: token_sacdigital}} = changeset, config) do
    user
    |> verify_token_sacdigital(token_sacdigital, config)
    |> case do
      true ->
        changeset

      _ ->
        changeset = %{changeset | validations: [{:current_token_sacdigital, {:verify_token_sacdigital, []}} | changeset.validations]}

        Changeset.add_error(changeset, :current_token_sacdigital, "is invalid", validation: :verify_token_sacdigital)
    end
  end

  @doc """
  Verifies a token_sacdigital in a struct.

  The token_sacdigital will be verified by using the `:token_sacdigital_hash_methods` in the
  configuration.

  To prevent timing attacks, a blank token_sacdigital will be passed to the hash method
  in the `:token_sacdigital_hash_methods` configuration option if the `:token_sacdigital_hash`
  is `nil`.
  """
  @spec verify_token_sacdigital(Ecto.Schema.t(), binary(), Config.t()) :: boolean()
  def verify_token_sacdigital(%{token_sacdigital_hash: nil}, _token_sacdigital, config) do
    config
    |> token_sacdigital_hash_method()
    |> apply([""])

    false
  end
  def verify_token_sacdigital(%{token_sacdigital_hash: token_sacdigital_hash}, token_sacdigital, config) do
    config
    |> token_sacdigital_verify_method()
    |> apply([token_sacdigital, token_sacdigital_hash])
  end

  defp maybe_require_token_sacdigital(%{data: %{token_sacdigital_hash: nil}} = changeset) do
    Changeset.validate_required(changeset, [:token_sacdigital])
  end
  defp maybe_require_token_sacdigital(changeset), do: changeset

  defp maybe_validate_token_sacdigital(changeset, config) do
    changeset
    |> Changeset.get_change(:token_sacdigital)
    |> case do
      nil -> changeset
      _   -> validate_token_sacdigital(changeset, config)
    end
  end

  defp validate_token_sacdigital(changeset, config) do
    token_sacdigital_min_length = Config.get(config, :token_sacdigital_min_length, @token_sacdigital_min_length)
    token_sacdigital_max_length = Config.get(config, :token_sacdigital_max_length, @token_sacdigital_max_length)

    Changeset.validate_length(changeset, :token_sacdigital, min: token_sacdigital_min_length, max: token_sacdigital_max_length)
  end

  defp maybe_put_token_sacdigital_hash(%Changeset{valid?: true, changes: %{token_sacdigital: token_sacdigital}} = changeset, config) do
    Changeset.put_change(changeset, :token_sacdigital_hash, hash_token_sacdigital(token_sacdigital, config))
  end
  defp maybe_put_token_sacdigital_hash(changeset, _config), do: changeset

  defp hash_token_sacdigital(token_sacdigital, config) do
    config
    |> token_sacdigital_hash_method()
    |> apply([token_sacdigital])
  end

  defp token_sacdigital_hash_method(config) do
    {token_sacdigital_hash_method, _} = token_sacdigital_hash_methods(config)

    token_sacdigital_hash_method
  end

  defp token_sacdigital_verify_method(config) do
    {_, token_sacdigital_verify_method} = token_sacdigital_hash_methods(config)

    token_sacdigital_verify_method
  end

  defp token_sacdigital_hash_methods(config) do
    Config.get(config, :token_sacdigital_hash_methods, {&TokenSacdigital.pbkdf2_hash/1, &TokenSacdigital.pbkdf2_verify/2})
  end

  defp email_validator(config) do
    Config.get(config, :email_validator, &__MODULE__.validate_email/1)
  end

  @doc """
  Validates an e-mail.

  This implementation has the following rules:

  - Split into local-part and domain at last `@` occurance
  - Local-part should;
    - be at most 64 octets
    - separate quoted and unquoted content with a single dot
    - only have letters, digits, and the following characters outside quoted
      content:
        ```text
        !#$%&'*+-/=?^_`{|}~.
        ```
    - not have any consecutive dots outside quoted content
  - Domain should;
    - be at most 255 octets
    - only have letters, digits, hyphen, and dots

  Unicode characters are permitted in both local-part and domain.
  """
  @spec validate_email(binary()) :: :ok | {:error, any()}
  def validate_email(email) do
    [domain | rest] =
      email
      |> String.split("@")
      |> Enum.reverse()

    local_part =
      rest
      |> Enum.reverse()
      |> Enum.join("@")

    cond do
      String.length(local_part) > 64 -> {:error, "local-part too long"}
      String.length(domain) > 255    -> {:error, "domain too long"}
      local_part == ""               -> {:error, "invalid format"}
      true                           -> validate_email(local_part, domain)
    end
  end

  defp validate_email(local_part, domain) do
    sanitized_local_part = remove_quotes_from_local_part(local_part)

    cond do
      local_part_only_quoted?(local_part) ->
        validate_domain(domain)

      local_part_consective_dots?(sanitized_local_part) ->
        {:error, "consective dots in local-part"}

      local_part_valid_characters?(sanitized_local_part) ->
        validate_domain(domain)

      true ->
        {:error, "invalid characters in local-part"}
    end
  end

  defp remove_quotes_from_local_part(local_part),
    do: Regex.replace(~r/(^\".*\"$)|(^\".*\"\.)|(\.\".*\"$)?/, local_part, "")

  defp local_part_only_quoted?(local_part), do: local_part =~ ~r/^"[^\"]+"$/

  defp local_part_consective_dots?(local_part), do: local_part =~ ~r/\.\./

  defp local_part_valid_characters?(sanitized_local_part),
    do: sanitized_local_part =~ ~r<^[\p{L}0-9!#$%&'*+-/=?^_`{|}~\.]+$>u

  defp validate_domain(domain) do
    cond do
      String.first(domain) == "-"     -> {:error, "domain begins with hyphen"}
      String.last(domain) == "-"      -> {:error, "domain ends with hyphen"}
      domain =~ ~r/^[\p{L}0-9-\.]+$/u -> :ok
      true                            -> {:error, "invalid characters in domain"}
    end
  end
end
