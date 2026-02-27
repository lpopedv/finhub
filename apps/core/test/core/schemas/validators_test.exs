defmodule Core.Schemas.ValidatorsTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  alias Core.Schemas.Validators

  defp email_changeset(email) do
    {%{}, %{email: :string}}
    |> cast(%{email: email}, [:email])
    |> Validators.validate_email(:email)
  end

  describe "validate_email/2" do
    @valid_emails [
      {"well-formed", "user@example.com"},
      {"with subdomain", "user@mail.example.com"},
      {"with plus tag", "user+tag@example.com"}
    ]

    @invalid_emails [
      {"without @", "userexample.com"},
      {"without domain", "user@"},
      {"without local part", "@example.com"},
      {"with spaces", "user @example.com"},
      {"without TLD", "user@example"}
    ]

    for {description, email} <- @valid_emails do
      test "accepts email #{description}" do
        assert email_changeset(unquote(email)).valid?
      end
    end

    for {description, email} <- @invalid_emails do
      test "rejects email #{description}" do
        changeset = email_changeset(unquote(email))

        refute changeset.valid?
        assert {"has invalid format", _} = changeset.errors[:email]
      end
    end

    test "does not add error when field is nil" do
      changeset =
        {%{}, %{email: :string}}
        |> cast(%{}, [:email])
        |> Validators.validate_email(:email)

      assert changeset.valid?
    end
  end
end
