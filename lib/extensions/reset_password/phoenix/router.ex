defmodule PowResetTokenSacdigital.Phoenix.Router do
  @moduledoc false
  use Pow.Extension.Phoenix.Router.Base

  alias Pow.Phoenix.Router

  defmacro routes(_config) do
    quote location: :keep do
      Router.pow_resources "/reset-token_sacdigital", ResetTokenSacdigitalController, only: [:new, :create, :update]
      Router.pow_route :get, "/reset-token_sacdigital/:id", ResetTokenSacdigitalController, :edit
    end
  end
end
