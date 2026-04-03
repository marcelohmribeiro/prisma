defmodule ProjetoPrisma.Repo.Migrations.AddUserIdToProfiles do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create index(:profiles, [:user_id])
  end
end
