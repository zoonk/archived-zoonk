defmodule UneebeeWeb.Shared.Paginate do
  @moduledoc """
  Reusable module for paginating items in a LiveView.

  ## Usage

      use UneebeeWeb.Shared.Paginate, as: :schools
      use UneebeeWeb.Shared.Paginate, as: :courses
  """

  alias Phoenix.LiveView.Socket

  defmacro __using__(opts) do
    as = Keyword.fetch!(opts, :as)

    quote do
      @spec add_pagination(Socket.t()) :: Socket.t()
      def add_pagination(socket) do
        socket |> assign(page: 1, per_page: 10) |> paginate(1)
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
            assign(socket, end_of_timeline?: at == -1)

          [_ | _] = items ->
            socket
            |> assign(end_of_timeline?: false)
            |> assign(:page, new_page)
            |> stream(unquote(as), items, at: at, limit: limit)
        end
      end
    end
  end
end
