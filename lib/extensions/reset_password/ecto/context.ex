defmodule PowResetTokenSacdigital.Ecto.Context do
  @moduledoc false
  alias Pow.{Config, Ecto.Context, Operations}
  alias PowResetTokenSacdigital.Ecto.Schema

  @spec get_by_email(binary(), Config.t()) :: Context.user() | nil
  def get_by_email(email, config), do: Operations.get_by([email: email], config)

  @spec update_token_sacdigital(Context.user(), map(), Config.t()) :: {:ok, Context.user()} | {:error, Context.changeset()}
  def update_token_sacdigital(user, params, config) do
    user
    |> Schema.reset_token_sacdigital_changeset(params)
    |> Context.do_update(config)
  end

  # TODO: Remove by 1.1.0
  @deprecated "Use `PowResetTokenSacdigital.Ecto.Schema.reset_token_sacdigital_changeset/2` instead"
  def token_sacdigital_changeset(user, params), do: Schema.reset_token_sacdigital_changeset(user, params)
end
