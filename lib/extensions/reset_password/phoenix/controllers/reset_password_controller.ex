defmodule PowResetTokenSacdigital.Phoenix.ResetTokenSacdigitalController do
  @moduledoc false
  use Pow.Extension.Phoenix.Controller.Base

  alias Plug.Conn
  alias Pow.Plug, as: PowPlug
  alias PowResetTokenSacdigital.{Phoenix.Mailer, Plug}

  plug :require_not_authenticated
  plug :load_user_from_reset_token when action in [:edit, :update]
  plug :assign_create_path when action in [:new, :create]
  plug :assign_update_path when action in [:edit, :update]

  @spec process_new(Conn.t(), map()) :: {:ok, map(), Conn.t()}
  def process_new(conn, _params) do
    {:ok, Plug.change_user(conn), conn}
  end

  @spec respond_new({:ok, map(), Conn.t()}) :: Conn.t()
  def respond_new({:ok, changeset, conn}) do
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  @spec process_create(Conn.t(), map()) :: {:ok | :error, map(), Conn.t()}
  def process_create(conn, %{"user" => user_params}) do
    Plug.create_reset_token(conn, user_params)
  end

  @spec respond_create({:ok | :error, map(), Conn.t()}) :: Conn.t()
  def respond_create({:ok, %{token: token, user: user}, conn}) do
    url = routes(conn).url_for(conn, __MODULE__, :edit, [token])
    deliver_email(conn, user, url)

    conn
    |> put_flash(:info, extension_messages(conn).email_has_been_sent(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end
  def respond_create({:error, changeset, conn}) do
    case PowPlug.__prevent_information_leak__(conn, nil) do
      true ->
        conn
        |> put_flash(:info, extension_messages(conn).maybe_email_has_been_sent(conn))
        |> redirect(to: routes(conn).session_path(conn, :new))

      false ->
        conn
        |> assign(:changeset, changeset)
        |> put_flash(:error, extension_messages(conn).user_not_found(conn))
        |> render("new.html")
    end
  end

  @spec process_edit(Conn.t(), map()) :: {:ok, map(), Conn.t()}
  def process_edit(conn, _params) do
    {:ok, Plug.change_user(conn), conn}
  end

  @spec respond_edit({:ok, map(), Conn.t()}) :: Conn.t()
  def respond_edit({:ok, changeset, conn}) do
    conn
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  @spec process_update(Conn.t(), map()) :: {:ok | :error, map(), Conn.t()}
  def process_update(conn, %{"user" => user_params}) do
    Plug.update_user_token_sacdigital(conn, user_params)
  end

  @spec respond_update({:ok, map(), Conn.t()}) :: Conn.t()
  def respond_update({:ok, _user, conn}) do
    conn
    |> put_flash(:info, extension_messages(conn).token_sacdigital_has_been_reset(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end
  def respond_update({:error, changeset, conn}) do
    conn
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  defp load_user_from_reset_token(%{params: %{"id" => token}} = conn, _opts) do
    case Plug.user_from_token(conn, token) do
      nil ->
        conn
        |> put_flash(:error, extension_messages(conn).invalid_token(conn))
        |> redirect(to: routes(conn).path_for(conn, __MODULE__, :new))
        |> halt()

      user ->
        Plug.assign_reset_token_sacdigital_user(conn, user)
    end
  end

  defp deliver_email(conn, user, url) do
    email = Mailer.reset_token_sacdigital(conn, user, url)

    Pow.Phoenix.Mailer.deliver(conn, email)
  end

  defp assign_create_path(conn, _opts) do
    path = routes(conn).path_for(conn, __MODULE__, :create)
    Conn.assign(conn, :action, path)
  end

  defp assign_update_path(conn, _opts) do
    token = conn.params["id"]
    path  = routes(conn).path_for(conn, __MODULE__, :update, [token])
    Conn.assign(conn, :action, path)
  end
end
