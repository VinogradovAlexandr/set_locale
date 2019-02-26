defmodule SetLocale do
  import Plug.Conn

  defmodule Config do
    defstruct gettext: nil, default_locale: nil, cookie_key: nil
  end

  def init(gettext: gettext, default_locale: default_locale, cookie_key: cookie_key) do
    %Config{gettext: gettext, default_locale: default_locale, cookie_key: cookie_key}
  end

  def init(gettext: gettext, default_locale: default_locale) do
    %Config{gettext: gettext, default_locale: default_locale, cookie_key: nil}
  end

  def init([gettext, default_locale]) do
    unless Mix.env() == :test do
      IO.warn(
        ~S(
        This config style has been deprecated for for set_locale. Please update the old style config:
        plug SetLocale, [MyApp.Gettext, "en-gb"]

        to the new config:
        plug SetLocale, gettext: MyApp.Gettext, default_locale: "en-gb", cookie_key: "preferred_locale"]
      ),
        Macro.Env.stacktrace(__ENV__)
      )
    end

    %Config{gettext: gettext, default_locale: default_locale, cookie_key: nil}
  end

  def call(
        %{
          params: %{
            "locale" => requested_locale
          }
        } = conn,
        config
      ) do
    if Enum.member?(supported_locales(config), requested_locale) do
      Gettext.put_locale(config.gettext, requested_locale)
      assign(conn, :locale, requested_locale)
    else
      Gettext.put_locale(config.gettext, config.default_locale)
      assign(conn, :locale, config.default_locale)
    end

    conn
  end

  def call(conn, config) do
    header_locale = get_locale_from_header(conn, config)

    if Enum.member?(supported_locales(config), header_locale) do
      Gettext.put_locale(config.gettext, header_locale)
      assign(conn, :locale, header_locale)
    else
      Gettext.put_locale(config.gettext, config.default_locale)
      assign(conn, :locale, config.default_locale)
    end

    conn
  end

  defp supported_locales(config), do: Gettext.known_locales(config.gettext)

  defp get_locale_from_header(conn, gettext) do
    conn
    |> SetLocale.Headers.extract_accept_language()
    |> Enum.find(nil, fn accepted_locale ->
      Enum.member?(supported_locales(gettext), accepted_locale)
    end)
  end
end
