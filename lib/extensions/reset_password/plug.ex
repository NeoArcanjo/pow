defmodule PowResetTokenSacdigital.Plug do
  @moduledoc """
  Plug helper methods.
  """
  alias Plug.Conn
  alias Pow.{Config, Plug, Store.Backend.EtsCache, UUID}
  alias PowResetTokenSacdigital.Ecto.Context, as: ResetTokenSacdigitalContext
  alias PowResetTokenSacdigital.{Ecto.Schema, Store.ResetTokenCache}

  @doc """
  Creates a changeset from the user fetched in the connection.
  """
  @spec change_user(Conn.t(), map()) :: map()
  def change_user(conn, params \\ %{}) do
    user = reset_token_sacdigital_user(conn) || user_struct(conn)

    Schema.reset_token_sacdigital_changeset(user, params)
  end

  defp user_struct(conn) do
    conn
    |> Plug.fetch_config()
    |> Config.user!()
    |> struct()
  end

  @doc """
  Assigns a `:reset_token_sacdigital_user` key with the user in the connection.
  """
  @spec assign_reset_token_sacdigital_user(Conn.t(), map()) :: Conn.t()
  def assign_reset_token_sacdigital_user(conn, user) do
    Conn.assign(conn, :reset_token_sacdigital_user, user)
  end

  @doc """
  Finds a user for the provided params, creates a token, and stores the user
  for the token.

  To prevent timing attacks, `Pow.UUID.generate/0` is called whether the user
  exists or not.

  `:reset_token_sacdigital_token_store` can be passed in the config for the conn. This
  value defaults to
  `{PowResetTokenSacdigital.Store.ResetTokenCache, backend: Pow.Store.Backend.EtsCache}`.
  The `Pow.Store.Backend.EtsCache` backend store can be changed with the
  `:cache_store_backend` option.
  """
  @spec create_reset_token(Conn.t(), map()) :: {:ok, map(), Conn.t()} | {:error, map(), Conn.t()}
  def create_reset_token(conn, params) do
    config = Plug.fetch_config(conn)
    token  = UUID.generate()

    params
    |> Map.get("email")
    |> ResetTokenSacdigitalContext.get_by_email(config)
    |> case do
      nil ->
        {:error, change_user(conn, params), conn}

      user ->
        {store, store_config} = store(config)

        store.put(store_config, token, user)

        {:ok, %{token: token, user: user}, conn}
    end
  end

  @doc """
  Fetches user from the store by the provided token.

  See `create_reset_token/2` for more on `:reset_token_sacdigital_token_store` config
  option.
  """
  @spec user_from_token(Conn.t(), binary()) :: map() | nil
  def user_from_token(conn, token) do
    {store, store_config} =
      conn
      |> Plug.fetch_config()
      |> store()

    store_config
    |> store.get(token)
    |> case do
      :not_found -> nil
      user       -> user
    end
  end

  @doc """
  Updates the token_sacdigital for the user fetched in the connection.

  See `create_reset_token/2` for more on `:reset_token_sacdigital_token_store` config
  option.
  """
  @spec update_user_token_sacdigital(Conn.t(), map()) :: {:ok, map(), Conn.t()} | {:error, map(), Conn.t()}
  def update_user_token_sacdigital(conn, params) do
    config = Plug.fetch_config(conn)
    token  = conn.params["id"]

    conn
    |> reset_token_sacdigital_user()
    |> ResetTokenSacdigitalContext.update_token_sacdigital(params, config)
    |> maybe_expire_token(conn, token, config)
  end

  defp maybe_expire_token({:ok, user}, conn, token, config) do
    expire_token(token, config)

    {:ok, user, conn}
  end
  defp maybe_expire_token({:error, changeset}, conn, _token, _config) do
    {:error, changeset, conn}
  end

  defp expire_token(token, config) do
    {store, store_config} = store(config)
    store.delete(store_config, token)
  end

  defp reset_token_sacdigital_user(conn) do
    conn.assigns[:reset_token_sacdigital_user]
  end

  defp store(config) do
    case Config.get(config, :reset_token_sacdigital_token_store, default_store(config)) do
      {store, store_config} -> {store, store_config}
      store                 -> {store, []}
    end
  end

  defp default_store(config) do
    backend = Config.get(config, :cache_store_backend, EtsCache)

    {ResetTokenCache, [backend: backend]}
  end
end
