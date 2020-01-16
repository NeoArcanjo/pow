defmodule Pow.Phoenix.RegistrationTemplate do
  @moduledoc false
  use Pow.Phoenix.Template

  template :new, :html,
  """
  <h1>Register</h1>

  <%= Pow.Phoenix.HTML.FormTemplate.render([
    {:text, {:changeset, :pow_user_id_field}},
    {:token_sacdigital, :token_sacdigital},
    {:token_sacdigital, :token_sacdigital_confirmation}
  ],
  button_label: "Register") %>

  <span><%%= link "Sign in", to: Routes.<%= Pow.Phoenix.Controller.route_helper(Pow.Phoenix.SessionController) %>_path(@conn, :new) %></span>
  """

  template :edit, :html,
  """
  <h1>Edit profile</h1>

  <%= Pow.Phoenix.HTML.FormTemplate.render([
    {:token_sacdigital, :current_token_sacdigital},
    {:text, {:changeset, :pow_user_id_field}},
    {:token_sacdigital, :token_sacdigital},
    {:token_sacdigital, :token_sacdigital_confirmation}
  ],
  button_label: "Update") %>
  """
end
