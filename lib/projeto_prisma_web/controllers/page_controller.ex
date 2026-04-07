defmodule ProjetoPrismaWeb.PageController do
  use ProjetoPrismaWeb, :controller

  alias ProjetoPrisma.Accounts

  def home(conn, _params) do
    render(conn, :home)
  end

  def connect_platforms(conn, _params) do
    render(conn, :connect_platforms)
  end

  def register(conn, _params) do
    render(conn, :register)
  end

  def create_profile(conn, %{"nickname" => nickname, "email" => email,
                           "password" => password, "full_name" => full_name}) do
    attrs = %{
      username: nickname |> String.trim() |> String.downcase() |> String.replace(~r/\s+/, "_"),
      email: email |> String.trim() |> String.downcase(),
      password: password,
      full_name: String.trim(full_name)
    }

    with {:ok, user} <- Accounts.register_user(attrs),
         {:ok, profile} <- Accounts.create_profile_for_user(user) do
      conn
      |> put_session(:user_id, user.id)
      |> put_session(:profile_id, profile.id)
      |> put_flash(:info, "Conta criada com sucesso!")
      |> redirect(to: ~p"/connect-platforms")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
        error_msg = errors |> Map.values() |> List.flatten() |> Enum.join(", ")

        conn
        |> put_flash(:error, "Erro ao criar conta: #{error_msg}")
        |> redirect(to: ~p"/register")
    end
  end

  def create_profile(conn, _params) do
    conn
    |> put_flash(:error, "Todos os campos sao obrigatorios")
    |> redirect(to: ~p"/register")
  end
end
