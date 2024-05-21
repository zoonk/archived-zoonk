defmodule Zoonk.Repo.Migrations.RemoveTrophiesWithoutMissionId do
  use Ecto.Migration

  import Ecto.Query

  alias Zoonk.Gamification.UserTrophy
  alias Zoonk.Repo

  def up do
    UserTrophy
    |> where([ut], ut.reason == ^:mission_completed and is_nil(ut.mission_id))
    |> Repo.delete_all()
  end
end
