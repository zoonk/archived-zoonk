# Permissions

When you're setting up UneeBee for the first time, we'll guide you into creating an account that will have `manager` permissions. There are three kind of roles users can have:

- **Manager**: Can manage everything in their school: school information, users, courses, etc.
- **Teacher**: Can manage courses and students.
- **Student**: Can only view courses.

## Default users

When you run `mix setup`, we add some seed data for you. This is helpful for testing different functionality such as user roles. The users below are created for you (password is always `Demo1234`):

| School  | Public? | Language | Domain       | Subdomain | Managers   | Teachers          |
| ------- | ------- | -------- | ------------ | --------- | ---------- | ----------------- |
| UneeBee | Yes     | English  | uneebee.test | -         | `einstein` | `curie`, `newton` |

## Approved vs non-approved users

Users can request to join private schools. When they do so, they'll be added to the school as a non-approved user. Non-approved users can't access the school's content.

Managers can see pending users on the "managers", "teachers", and "students" pages. They can approve or reject users from there. When a user is approved, they'll be able to access the school's content. Otherwise, they'll be removed from the school.

## Private vs public schools

Schools can be private or public. Public schools are open to anyone. Private schools are only accessible to users who are approved by the school's managers.

## Public vs private courses

Courses can be private or public. Public courses are open to anyone **within the school**. If the school is public, this means anyone can see all public courses. However, if the school is private, then only school members can see public courses.

Private courses are only accessible to users who are approved by the course's teachers.

## Published vs unpublished courses

Courses can be published or unpublished. Published courses are visible to students. Unpublished courses are only visible to teachers and managers. Unpublished courses are useful as a way to draft a course before publishing it.
