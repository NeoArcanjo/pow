defmodule PowResetTokenSacdigital.Phoenix.Messages do
  @moduledoc false

  @doc """
  Flash message to show generic response for reset token_sacdigital request.
  """
  def maybe_email_has_been_sent(_conn), do: "If an account for the provided email exists, an email with reset instructions will be send to you. Please check your inbox."

  @doc """
  Flash message to show when a reset token_sacdigital e-mail has been sent. Falls back
  to `maybe_email_has_been_sent/1`
  """
  def email_has_been_sent(conn), do: maybe_email_has_been_sent(conn)

  @doc """
  Flash message to show when no user exists for the provided e-mail.
  """
  def user_not_found(_conn), do: "No account exists for the provided email. Please try again."

  @doc """
  Flash message to show when a an invalid or expired reset token_sacdigital link is
  used.
  """
  def invalid_token(_conn), do: "The reset token has expired."

  @doc """
  Flash message to show when token_sacdigital has been updated.
  """
  def token_sacdigital_has_been_reset(_conn), do: "The token_sacdigital has been updated."
end
