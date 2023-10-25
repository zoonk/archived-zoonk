defmodule Uneebee.Repo.Migrations.RemoveSchoolUserWhenUserIsDeleted do
  use Ecto.Migration

  def change do
    drop constraint("school_users", "school_users_approved_by_id_fkey")

    alter table(:school_users) do
      modify :approved_by_id, references(:users, on_delete: :delete_all)
    end
  end
end
