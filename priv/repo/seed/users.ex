defmodule UserSeed do
  @moduledoc false

  alias Uneebee.Accounts

  @users [
    %{
      first_name: "Albert",
      last_name: "Einstein",
      email: "einstein@example.com",
      username: "einstein",
      date_of_birth: "1979-03-14",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/einstein.jpeg"
    },
    %{
      first_name: "Marie",
      last_name: "Curie",
      email: "curie@example.com",
      username: "curie",
      date_of_birth: "1967-11-07",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/curie.jpeg"
    },
    %{
      first_name: "Isaac",
      last_name: "Newton",
      email: "newton@example.com",
      username: "newton",
      date_of_birth: "1943-01-04",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/newton.jpeg"
    },
    %{
      first_name: "Ada",
      last_name: "Lovelace",
      email: "lovelace@example.com",
      username: "lovelace",
      date_of_birth: "1915-12-10",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/lovelace.jpeg"
    },
    %{
      first_name: "Nikola",
      last_name: "Tesla",
      email: "tesla@example.com",
      username: "tesla",
      date_of_birth: "1956-07-10",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/tesla.jpeg"
    },
    %{
      first_name: "Rosie",
      last_name: "Franklin",
      email: "franklin@example.com",
      username: "franklin",
      date_of_birth: "1970-07-25",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/franklin.jpeg"
    },
    %{
      first_name: "Louis",
      last_name: "Pasteur",
      email: "pasteur@example.com",
      username: "pasteur",
      date_of_birth: "1992-12-27",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/pasteur.jpeg"
    },
    %{
      first_name: "Leonardo",
      last_name: "da Vinci",
      email: "davinci@example.com",
      username: "davinci",
      date_of_birth: "1952-04-15",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/davinci.jpeg"
    },
    %{
      first_name: "Jane",
      last_name: "Goodall",
      email: "goodall@example.com",
      username: "goodall",
      date_of_birth: "1984-04-03",
      language: :en,
      password: "Demo1234",
      avatar: "/uploads/seed/users/goodall.jpeg"
    }
  ]

  @doc """
  Inserts the users into the database.

  Iterate over the users list and insert each user into the database.
  """
  def seed(args \\ %{}) do
    multiple? = Map.get(args, :multiple?, false)
    users = generate_user_attrs(multiple?)
    Enum.each(users, &Accounts.register_user/1)
  end

  defp generate_user_attrs(false), do: @users
  defp generate_user_attrs(true), do: generate_user_attrs()

  defp generate_user_attrs() do
    random_users =
      Enum.map(1..200, fn idx ->
        %{
          email: "user_#{idx}@example.com",
          username: "user_#{idx}",
          language: :en,
          password: "Demo1234"
        }
      end)

    @users ++ random_users
  end
end
