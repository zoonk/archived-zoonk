defmodule Uneebee.Repo.Migrations.RemoveTrophiesWithoutMissionId do
  use Ecto.Migration

  import Ecto.Query

  alias Uneebee.Gamification.UserTrophy
  alias Uneebee.Repo

  def up do
    UserTrophy
    |> where([ut], ut.reason == ^:mission_completed and is_nil(ut.mission_id))
    |> Repo.delete_all()
  end
end
