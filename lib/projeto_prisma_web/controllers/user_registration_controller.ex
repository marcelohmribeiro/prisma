defmodule ProjetoPrismaWeb.UserRegistrationController do
  use ProjetoPrismaWeb, :controller

  alias ProjetoPrisma.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        conn
        |> put_flash(
          :info,
          "Enviamos um e-mail para #{user.email}. Acesse-o para confirmar sua conta."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
