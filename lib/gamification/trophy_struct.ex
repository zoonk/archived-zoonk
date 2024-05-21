defmodule Zoonk.Gamification.Trophy do
  @moduledoc """
  Struct for defining a trophy.

  This is used to track supported trophies.
  """
  @type t :: %__MODULE__{
          key: atom(),
          label: String.t(),
          description: String.t()
        }

  defstruct key: nil, label: "", description: ""
end
