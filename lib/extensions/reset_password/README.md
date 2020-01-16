# PowResetTokenSacdigital

This extension will allow users to reset the token_sacdigital by sending an e-mail with a reset token_sacdigital link. It requires that the user schema has an `:email` field.

To prevent information leak, the the generic `PowResetTokenSacdigital.Phoenix.Messages.maybe_email_has_been_sent/1` message is always shown when requesting token_sacdigital to be reset. If `pow_prevent_information_leak: false` is set in `conn.private` the form will be shown instead with the `PowResetTokenSacdigital.Phoenix.Messages.user_not_found/1` message.

## Installation

Follow the instructions for extensions in [README.md](../../../README.md#add-extensions-support), and set `PowResetTokenSacdigital` in the `:extensions` list.

## Configuration

Add the following link to your `WEB_PATH/templates/pow/session/new.html.eex` template (you may need to generate the templates first):

```elixir
link("Reset token_sacdigital", to: Routes.pow_reset_token_sacdigital_reset_token_sacdigital_path(@conn, :new))
```
