Code.require_file("priv/repo/seed/users.ex")
Code.require_file("priv/repo/seed/schools.ex")
Code.require_file("priv/repo/seed/courses.ex")

args = System.argv()

kind =
  args
  |> Enum.find(fn arg -> String.starts_with?(arg, "--kind=") end)
  |> String.split("=")
  |> List.last()
  |> String.to_atom()

UserSeed.seed()
SchoolSeed.seed(kind)
CourseSeed.seed()
