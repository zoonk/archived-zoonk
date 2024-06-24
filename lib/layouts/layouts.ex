defmodule ZoonkWeb.Layouts do
  @moduledoc false
  use ZoonkWeb, :html

  import ZoonkWeb.Components.Layouts.AppMenu
  import ZoonkWeb.Components.Layouts.DashboardMenuItem
  import ZoonkWeb.Components.Layouts.MenuDesktop
  import ZoonkWeb.Components.Layouts.MenuMobile
  import ZoonkWeb.Layouts.MenuUtils

  alias Zoonk.Organizations.School
  alias Zoonk.Organizations.SchoolUser
  alias ZoonkWeb.Components.Layouts.CourseSelect
  alias ZoonkWeb.Components.Layouts.LessonSelect

  embed_templates "templates/*"

  @spec social_image(String.t() | nil, School.t() | nil) :: String.t()
  def social_image(nil, school), do: school_logo(school, nil)
  def social_image(img, _school), do: img

  @spec page_title(String.t() | nil, School.t() | nil) :: String.t()
  def page_title(nil, school), do: school_name(school)
  def page_title(title, _school), do: title

  @spec plausible_domain(School.t()) :: String.t() | nil
  def plausible_domain(%School{} = app), do: app.custom_domain
  def plausible_domain(_school), do: nil

  @spec enable_plausible?(SchoolUser.t() | nil) :: boolean()
  def enable_plausible?(%SchoolUser{} = school_user), do: school_user.analytics?
  def enable_plausible?(nil), do: true
end
