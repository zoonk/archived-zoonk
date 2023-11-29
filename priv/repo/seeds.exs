Code.require_file("priv/repo/seed/users.ex")
Code.require_file("priv/repo/seed/schools.ex")
Code.require_file("priv/repo/seed/courses.ex")
Code.require_file("priv/repo/seed/seed.ex")

args = System.argv()
kind = Seed.get_kind(args)
multiple? = Seed.multiple_schools?(args)

UserSeed.seed()
SchoolSeed.seed(%{kind: kind, multiple?: multiple?})
CourseSeed.seed()
