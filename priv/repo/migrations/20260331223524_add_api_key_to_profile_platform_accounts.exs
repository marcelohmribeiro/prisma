defmodule ProjetoPrisma.Repo.Migrations.AddApiKeyToProfilePlatformAccounts do
  use Ecto.Migration

  def change do
    alter table(:profile_platform_accounts) do
      add :api_key, :string
    end
  end
end
