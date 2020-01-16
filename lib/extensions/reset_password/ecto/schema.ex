defmodule PowResetTokenSacdigital.Ecto.Schema do
  @moduledoc false
  use Pow.Extension.Ecto.Schema.Base

  alias Ecto.Changeset
  alias Pow.Extension.Ecto.Schema

  @impl true
  def validate!(_config, module) do
    Schema.require_schema_field!(module, :email, PowResetTokenSacdigital)
  end

  @spec reset_token_sacdigital_changeset(map(), map()) :: Changeset.t()
  def reset_token_sacdigital_changeset(%user_mod{} = user, params) do
    user
    |> user_mod.pow_token_sacdigital_changeset(params)
    |> Changeset.validate_required([:token_sacdigital])
  end
end
