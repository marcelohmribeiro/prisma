defmodule ProjetoPrisma.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :full_name, :string
    field :username, :string

    has_one :profile, ProjetoPrisma.Accounts.Profile

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :full_name, :username])
    |> validate_required([:email, :password, :username])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "deve ter formato valido")
    |> validate_length(:password, min: 6, message: "deve ter no minimo 6 caracteres")
    |> validate_length(:username, min: 3, message: "deve ter no minimo 3 caracteres")
    |> validate_format(:username, ~r/^[a-z0-9_]+$/, message: "apenas letras, numeros e underscore")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> hash_password()
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    end
  end
end
