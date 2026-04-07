defmodule ProjetoPrisma.Accounts.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :username, :string
    belongs_to :user, ProjetoPrisma.Accounts.User
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:username, :user_id])
    |> validate_required([:username])
  end
end
