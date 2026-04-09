defmodule ProjetoPrisma.Repo.Migrations.RemoveLegacyPasswordHashFromUsers do
  use Ecto.Migration

  def up do
    # Safety backfill before dropping the legacy column.
    execute "UPDATE users SET hashed_password = password_hash WHERE hashed_password IS NULL AND password_hash IS NOT NULL",
            ""

    execute "ALTER TABLE users DROP COLUMN IF EXISTS password_hash", ""
  end

  def down do
    alter table(:users) do
      add_if_not_exists :password_hash, :string
    end

    execute "UPDATE users SET password_hash = hashed_password WHERE password_hash IS NULL AND hashed_password IS NOT NULL",
            ""
  end
end
