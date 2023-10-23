defmodule UneebeeWeb.Layouts do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Components.Layouts.MenuDesktop
  import UneebeeWeb.Components.Layouts.MenuMobile

  alias Uneebee.Organizations.School

  embed_templates "templates/*"

  @spec school_name(School.t() | nil) :: String.t()
  def school_name(nil), do: "UneeBee"
  def school_name(%School{} = school), do: school.name

  @spec school_logo(School.t() | nil) :: String.t()
  def school_logo(nil), do: ~p"/images/logo.svg"
  def school_logo(%School{logo: nil}), do: school_logo(nil)
  def school_logo(%School{} = school), do: school.logo

  @spec social_image(String.t() | nil, School.t() | nil) :: String.t()
  def social_image(nil, school), do: school_logo(school)
  def social_image(img, _school), do: img

  @spec page_title(String.t() | nil, School.t() | nil) :: String.t()
  def page_title(nil, school), do: school_name(school)
  def page_title(title, _school), do: title
end
