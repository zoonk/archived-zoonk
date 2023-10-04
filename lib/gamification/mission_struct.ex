defmodule Uneebee.Gamification.Mission do
  @moduledoc """
  Struct for defining a mission.

  This is used to track supported missions.
  """
  @type t :: %__MODULE__{
          key: atom(),
          prize: :trophy | :gold | :silver | :bronze,
          label: String.t(),
          description: String.t(),
          success_message: String.t()
        }

  defstruct key: nil, prize: :trophy, label: "", description: "", success_message: ""
end
