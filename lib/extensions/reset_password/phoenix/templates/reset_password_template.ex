defmodule PowResetTokenSacdigital.Phoenix.ResetTokenSacdigitalTemplate do
  @moduledoc false
  use Pow.Phoenix.Template

  template :new, :html,
  """
  <h1>Reset token_sacdigital</h1>

  <%= Pow.Phoenix.HTML.FormTemplate.render([
    {:text, :email}
  ]) %>
  """

  template :edit, :html,
  """
  <h1>Reset token_sacdigital</h1>

  <%= Pow.Phoenix.HTML.FormTemplate.render([
    {:token_sacdigital, :token_sacdigital},
    {:token_sacdigital, :token_sacdigital_confirmation}
  ]) %>

  <span><%%= link "Sign in", to: Routes.<%= Pow.Phoenix.Controller.route_helper(Pow.Phoenix.SessionController) %>_path(@conn, :new) %></span>
  """
end
