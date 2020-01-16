defmodule PowResetTokenSacdigital.Phoenix.Mailer do
  @moduledoc false
  alias Plug.Conn
  alias Pow.Phoenix.Mailer.Mail
  alias PowResetTokenSacdigital.Phoenix.MailerView

  @spec reset_token_sacdigital(Conn.t(), map(), binary()) :: Mail.t()
  def reset_token_sacdigital(conn, user, url) do
    Mail.new(conn, user, {MailerView, :reset_token_sacdigital}, url: url)
  end
end
