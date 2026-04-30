defmodule ProjetoPrisma.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:users) do
      add_if_not_exists :hashed_password, :string
      add_if_not_exists :confirmed_at, :utc_datetime
    end

    execute "UPDATE users SET hashed_password = password_hash WHERE hashed_password IS NULL AND password_hash IS NOT NULL",
            ""

    execute "CREATE UNIQUE INDEX IF NOT EXISTS users_email_index ON users (email)", ""

    execute """
            CREATE TABLE IF NOT EXISTS users_tokens (
              id bigserial PRIMARY KEY,
              user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              token bytea NOT NULL,
              context varchar(255) NOT NULL,
              sent_to varchar(255),
              authenticated_at timestamp(0),
              inserted_at timestamp(0) NOT NULL
            )
            """,
            ""

    execute "CREATE INDEX IF NOT EXISTS users_tokens_user_id_index ON users_tokens (user_id)", ""

    execute "CREATE UNIQUE INDEX IF NOT EXISTS users_tokens_context_token_index ON users_tokens (context, token)",
            ""
  end
end
