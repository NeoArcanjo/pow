defmodule PowResetTokenSacdigital.Phoenix.MailerTemplate do
  @moduledoc false
  use Pow.Phoenix.Mailer.Template

  template :reset_token_sacdigital,
  "Reset token_sacdigital link",
  """
  Hi,

  Please use the following link to reset your token_sacdigital:

  <%= @url %>

  You can disregard this email if you didn't request a token_sacdigital reset.
  """,
  """
  <%= content_tag(:h3, "Hi,") %>
  <%= content_tag(:p, "Please use the following link to reset your token_sacdigital:") %>
  <%= content_tag(:p, link(@url, to: @url)) %>
  <%= content_tag(:p, "You can disregard this email if you didn't request a token_sacdigital reset.") %>
  """
end
