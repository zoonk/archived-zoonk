# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Shared.Paginate do
  @moduledoc """
  Reusable module for paginating items in a LiveView.

  ## Usage

      use UneebeeWeb.Shared.Paginate, as: :schools

      def mount(_params, _session, socket) do
        {:ok, add_pagination(socket)}
      end

      defp paginate(socket, new_page) when new_page >= 1 do
        %{per_page: per_page, school: school} = socket.assigns
        schools = Organizations.list_schools(school.id, offset: (new_page - 1) * per_page, limit: per_page)
        paginate(socket, new_page, schools)
      end
  """

  defmacro __using__(opts) do
    as = Keyword.fetch!(opts, :as)

    quote do
      def add_pagination(socket, per_page \\ 20) do
        socket |> assign(page: 1, per_page: per_page) |> paginate(1)
      end

      @impl Phoenix.LiveView
      def handle_event("next-page", _params, socket) do
        {:noreply, paginate(socket, socket.assigns.page + 1)}
      end

      def handle_event("prev-page", %{"_overran" => true}, socket) do
        {:noreply, paginate(socket, 1)}
      end

      def handle_event("prev-page", _params, socket) do
        if socket.assigns.page > 1 do
          {:noreply, paginate(socket, socket.assigns.page - 1)}
        else
          {:noreply, socket}
        end
      end

      defp paginate(socket, new_page, items) do
        %{per_page: per_page, page: cur_page} = socket.assigns

        {items, at, limit} =
          if new_page >= cur_page do
            {items, -1, per_page * 3 * -1}
          else
            {Enum.reverse(items), 0, per_page * 3}
          end

        case items do
          [] ->
            socket
            |> assign(end_of_timeline?: at == -1)
            |> maybe_assign_stream()

          [_ | _] = items ->
            socket
            |> assign(end_of_timeline?: false)
            |> assign(:page, new_page)
            |> stream(unquote(as), items, at: at, limit: limit)
        end
      end

      # If the stream doesn't exist, assign it to the socket
      defp maybe_assign_stream(%{assigns: %{streams: streams}} = socket), do: socket
      defp maybe_assign_stream(socket), do: stream(socket, unquote(as), [])
    end
  end
end
