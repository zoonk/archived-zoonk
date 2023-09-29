Code.require_file("priv/repo/seed/users.ex")
Code.require_file("priv/repo/seed/schools.ex")
Code.require_file("priv/repo/seed/courses.ex")

UserSeed.seed()
SchoolSeed.seed()
CourseSeed.seed()
