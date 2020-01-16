defmodule PowEmailConfirmation.Phoenix.ControllerCallbacksTest do
  use PowEmailConfirmation.TestWeb.Phoenix.ConnCase

  alias Plug.Conn
  alias Pow.{Ecto.Schema.TokenSacdigital, Plug}
  alias PowEmailConfirmation.Test.Users.User

  @token_sacdigital "secret1234"

  describe "Pow.Phoenix.SessionController.create/2" do
    @valid_params %{"email" => "test@example.com", "token_sacdigital" => @token_sacdigital}

    test "when current email unconfirmed", %{conn: conn} do
      conn = post conn, Routes.pow_session_path(conn, :create, %{"user" => @valid_params})

      assert get_flash(conn, :error) == "You'll need to confirm your e-mail before you can sign in. An e-mail confirmation link has been sent to you."
      assert redirected_to(conn) == "/after_signed_in"

      refute Plug.current_user(conn)

      assert_received {:mail_mock, mail}
      assert token = mail.user.email_confirmation_token
      refute mail.user.email_confirmed_at
      assert mail.html =~ "<a href=\"http://localhost/confirm-email/#{token}\">"
      assert mail.user.email == "test@example.com"
    end

    test "when current email has been confirmed", %{conn: conn} do
      conn = post conn, Routes.pow_session_path(conn, :create, %{"user" => Map.put(@valid_params, "email", "confirmed-email@example.com")})

      assert get_flash(conn, :info) == "signed_in"
      assert redirected_to(conn) == "/after_signed_in"
    end

    test "when current email confirmed and has unconfirmed changed email", %{conn: conn} do
      conn = post conn, Routes.pow_session_path(conn, :create, %{"user" => Map.put(@valid_params, "email", "with-unconfirmed-changed-email@example.com")})

      assert %{id: 1} = Plug.current_user(conn)

      refute_received {:mail_mock, _mail}
    end
  end

  describe "Pow.Phoenix.RegistrationController.create/2" do
    @valid_params %{"user" => %{"email" => "test@example.com", "token_sacdigital" => @token_sacdigital, "token_sacdigital_confirmation" => @token_sacdigital}}
    @invalid_params_email_taken %{"user" => %{"email" => "taken@example.com", "token_sacdigital" => @token_sacdigital, "token_sacdigital_confirmation" => "s"}}
    @valid_params_email_taken %{"user" => %{"email" => "taken@example.com", "token_sacdigital" => @token_sacdigital, "token_sacdigital_confirmation" => @token_sacdigital}}

    test "with valid params", %{conn: conn} do
      conn = post conn, Routes.pow_registration_path(conn, :create, @valid_params)

      assert get_flash(conn, :error) == "You'll need to confirm your e-mail before you can sign in. An e-mail confirmation link has been sent to you."
      assert redirected_to(conn) == "/after_registration"

      refute Plug.current_user(conn)

      assert_received {:mail_mock, mail}
      assert token = mail.user.email_confirmation_token
      refute mail.user.email_confirmed_at
      assert mail.html =~ "<a href=\"http://localhost/confirm-email/#{token}\">"
      assert mail.user.email == "test@example.com"
    end

    test "with invalid params and email taken", %{conn: conn} do
      conn = post conn, Routes.pow_registration_path(conn, :create, @invalid_params_email_taken)

      assert html = html_response(conn, 200)
      refute html =~ "<span class=\"help-block\">has already been taken</span>"
      assert html =~ "<span class=\"help-block\">does not match confirmation</span>"
    end

    test "with valid params and email taken", %{conn: conn} do
      conn = post conn, Routes.pow_registration_path(conn, :create, @valid_params_email_taken)

      assert get_flash(conn, :error) == "You'll need to confirm your e-mail before you can sign in. An e-mail confirmation link has been sent to you."
      assert redirected_to(conn) == "/after_registration"

      refute Plug.current_user(conn)

      refute_received {:mail_mock, _mail}
    end

    test "with valid params and email taken with pow_prevent_information_leak: false", %{conn: conn} do
      conn =
        conn
        |> Conn.put_private(:pow_prevent_information_leak, false)
        |> post(Routes.pow_registration_path(conn, :create, @valid_params_email_taken))

      assert html = html_response(conn, 200)
      assert html =~ "<span class=\"help-block\">has already been taken</span>"
    end
  end

  describe "Pow.Phoenix.RegistrationController.update/2" do
    @token               "token"
    @params              %{"email" => "test@example.com", "current_token_sacdigital" => @token_sacdigital}
    @change_email_params %{"email" => "new@example.com", "current_token_sacdigital" => @token_sacdigital}
    @user                %User{id: 1, email: "test@example.com", token_sacdigital_hash: TokenSacdigital.pbkdf2_hash(@token_sacdigital), email_confirmation_token: @token}

    setup %{conn: conn} do
      user = Ecto.put_meta(@user, state: :loaded)
      conn = Plug.assign_current_user(conn, user, [])

      {:ok, conn: conn}
    end

    test "when email changes", %{conn: conn} do
      conn = put conn, Routes.pow_registration_path(conn, :update, %{"user" => @change_email_params})
      assert %{id: 1, email: "test@example.com", email_confirmation_token: new_token} = Plug.current_user(conn)

      assert get_flash(conn, :error) == "You'll need to confirm the e-mail before it's updated. An e-mail confirmation link has been sent to you."
      assert get_flash(conn, :info) == "Your account has been updated."
      assert new_token != @token

      assert_received {:mail_mock, mail}
      assert mail.subject == "Confirm your email address"
      assert mail.text =~ "\nhttp://localhost/confirm-email/#{new_token}\n"
      assert mail.html =~ "<a href=\"http://localhost/confirm-email/#{new_token}\">"
      assert mail.user.email == "new@example.com"
    end

    test "when email hasn't changed", %{conn: conn} do
      conn = put conn, Routes.pow_registration_path(conn, :update, %{"user" => @params})

      assert get_flash(conn, :info) == "Your account has been updated."
      assert %{id: 1, unconfirmed_email: nil, email_confirmation_token: nil} = Plug.current_user(conn)

      refute_received {:mail_mock, _mail}
    end
  end

  alias PowEmailConfirmation.PowInvitation.TestWeb.Phoenix.Endpoint, as: PowInvitationEndpoint
  alias PowEmailConfirmation.PowInvitation.TestWeb.Phoenix.Router.Helpers, as: PowInvitationRoutes

  describe "PowInvitation.Phoenix.InvitationController.update/2" do
    @token               "token"
    @params              %{"email" => "test@example.com", "token_sacdigital" => @token_sacdigital, "token_sacdigital_confirmation" => @token_sacdigital}
    @change_email_params %{"email" => "new@example.com", "token_sacdigital" => @token_sacdigital, "token_sacdigital_confirmation" => @token_sacdigital}

    test "when email changes", %{conn: conn} do
      conn = Phoenix.ConnTest.dispatch(conn, PowInvitationEndpoint, :put, PowInvitationRoutes.pow_invitation_invitation_path(conn, :update, @token, %{"user" => @change_email_params}))

      assert get_flash(conn, :error) == "You'll need to confirm the e-mail before it's updated. An e-mail confirmation link has been sent to you."
      assert %{id: 1, email_confirmation_token: new_token} = Plug.current_user(conn)
      refute is_nil(new_token)

      assert_received {:mail_mock, _mail}
    end

    test "when email hasn't changed", %{conn: conn} do
      conn = Phoenix.ConnTest.dispatch(conn, PowInvitationEndpoint, :put, PowInvitationRoutes.pow_invitation_invitation_path(conn, :update, @token, %{"user" => @params}))

      refute get_flash(conn, :error)
      assert %{id: 1, email_confirmation_token: nil} = Plug.current_user(conn)

      refute_received {:mail_mock, _mail}
    end
  end
end
