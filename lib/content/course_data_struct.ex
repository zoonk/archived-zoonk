defmodule Uneebee.Content.CourseData do
  @moduledoc """
  Struct for defining a course's data.

  It's used in the course list page to display additional information about each course.
  """
  alias Uneebee.Content.Course
  alias Uneebee.Content.CourseUser

  @type t :: %__MODULE__{id: integer(), data: Course.t() | CourseUser.t(), student_count: integer()}

  defstruct id: 0, data: %{}, student_count: 0
end
