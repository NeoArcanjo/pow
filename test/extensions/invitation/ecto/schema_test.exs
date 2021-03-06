defmodule PowInvitation.Ecto.SchemaTest do
  use ExUnit.Case
  doctest PowInvitation.Ecto.Schema

  alias PowInvitation.Ecto.Schema
  alias PowInvitation.PowEmailConfirmation.Test.Users.User, as: UserEmailConfirmation
  alias PowInvitation.Test.Users.User

  defmodule OverrideInviteChangesetUser do
    @moduledoc false
    use Ecto.Schema
    use Pow.Ecto.Schema
    use Pow.Extension.Ecto.Schema,
      extensions: [PowInvitation]

    schema "users" do
      field :organization_id, :integer

      pow_user_fields()

      timestamps()
    end

    def invite_changeset(user_or_changeset, invited_by, params) do
      user_or_changeset
      |> pow_invite_changeset(invited_by, params)
      |> Ecto.Changeset.put_change(:organization_id, 1)
    end
  end

  test "user_schema/1" do
    user = %User{}

    assert Map.has_key?(user, :invitation_token)
    assert Map.has_key?(user, :invitation_accepted_at)
    assert Map.has_key?(user, :invited_by)
    assert Map.has_key?(user, :invited_users)
  end

  describe "invite_changeset/3" do
    @valid_params %{email: "test@example.com"}
    @invited_by %User{id: 1}
    @invalid_params %{email: "foo"}

    test "with valid params" do
      changeset = Schema.invite_changeset(%User{}, @invited_by, @valid_params)

      assert changeset.valid?
      assert changeset.changes.email == "test@example.com"
      assert changeset.changes.invitation_token
      assert changeset.data.invited_by_id == @invited_by.id
    end

    test "with invalid params" do
      changeset = Schema.invite_changeset(%User{}, @invited_by, @invalid_params)

      refute changeset.valid?
      assert changeset.errors[:email]
    end

    test "with overridden method" do
      changeset = OverrideInviteChangesetUser.invite_changeset(%OverrideInviteChangesetUser{}, @invited_by, @valid_params)

      assert changeset.valid?
      assert changeset.changes.organization_id == 1
    end
  end

  describe "accept_invitation_changeset/2" do
    @token_sacdigital "token_sacdigital12"
    @valid_params %{email: "test@example.com", token_sacdigital: @token_sacdigital, token_sacdigital_confirmation: @token_sacdigital}
    @invalid_params %{email: "foo"}

    test "with valid params" do
      changeset = Schema.accept_invitation_changeset(%User{}, @valid_params)

      assert changeset.valid?
      assert changeset.changes.email == "test@example.com"
      assert changeset.changes.invitation_accepted_at
    end

    test "with invalid params" do
      changeset = Schema.accept_invitation_changeset(%User{}, @invalid_params)

      refute changeset.valid?
      assert changeset.errors[:email]
      assert changeset.errors[:token_sacdigital]
    end

    test "with PowEmailConfirmation extension" do
      user = Ecto.put_meta(%UserEmailConfirmation{email: "test@example.com"}, state: :loaded)

      changeset = Schema.accept_invitation_changeset(user, @valid_params)

      assert changeset.valid?
      refute changeset.changes[:email_confirmation_token]
      refute changeset.changes[:unconfirmed_email]

      changeset = Schema.accept_invitation_changeset(user, %{@valid_params | email: "new@example.com"})

      assert changeset.valid?
      assert changeset.changes[:email_confirmation_token]
      assert changeset.changes[:unconfirmed_email] == "new@example.com"
    end
  end
end
