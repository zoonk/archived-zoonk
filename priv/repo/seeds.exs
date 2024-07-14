Code.require_file("priv/repo/seed/users.ex")
Code.require_file("priv/repo/seed/schools.ex")
Code.require_file("priv/repo/seed/courses.ex")
Code.require_file("priv/repo/seed/seed.ex")

args = System.argv()
multiple? = Seed.multiple?(args)

seed_args = %{multiple?: multiple?}

UserSeed.seed(seed_args)
SchoolSeed.seed(seed_args)
CourseSeed.seed(seed_args)
