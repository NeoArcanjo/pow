defmodule Pow.Ecto.Schema.Fields do
  @moduledoc """
  Handles the Ecto schema fields for user.
  """
  alias Pow.{Config, Ecto.Schema}

  @attrs [
    {:token_sacdigital_hash, :string},
    {:current_token_sacdigital, :string, virtual: true},
    {:token_sacdigital, :string, virtual: true}
  ]

  @doc """
  List of attributes for the ecto schema.
  """
  @spec attrs(Config.t()) :: [tuple()]
  def attrs(config) do
    user_id_field = Schema.user_id_field(config)

    [{user_id_field, :string, null: false}] ++ @attrs
  end

  @doc """
  List of indexes for the ecto schema.
  """
  @spec indexes(Config.t()) :: [tuple()]
  def indexes(config) do
    user_id_field = Schema.user_id_field(config)

    [{user_id_field, true}]
  end
end
