defmodule Mix.Tasks.Pow.Extension.Phoenix.Gen.Templates do
  @shortdoc "Generates views and templates for extensions"

  @moduledoc """
  Generates views and templates for extensions.

      mix pow.extension.phoenix.gen.templates --extension PowResetTokenSacdigital --extension PowEmailConfirmation

      mix pow.extension.phoenix.gen.templates --context-app my_app --extension PowResetTokenSacdigital

  ## Arguments

    * `--extension` - extension to generate templates for
    * `--context-app` - context app to use for path and module names
  """
  use Mix.Task

  alias Mix.{Pow, Pow.Extension, Pow.Phoenix}

  @switches [context_app: :string, extension: :keep]
  @default_opts []
  @mix_task "pow.extension.phoenix.gen.templates"

  @impl true
  def run(args) do
    Pow.no_umbrella!(@mix_task)
    Pow.ensure_phoenix!(@mix_task, args)

    args
    |> Pow.parse_options(@switches, @default_opts)
    |> create_template_files()
    |> print_shell_instructions()
  end

  @extension_templates %{
    PowResetTokenSacdigital => [
      {"reset_token_sacdigital", ~w(new edit)}
    ],
    PowInvitation => [
      {"invitation", ~w(new show edit)}
    ]
  }
  defp create_template_files({config, _parsed, _invalid}) do
    structure  = Phoenix.parse_structure(config)
    web_module = structure[:web_module]
    web_prefix = structure[:web_prefix]
    web_app    = structure[:web_app]

    extensions =
      config
      |> Extension.extensions(web_app)
      |> Enum.map(fn extension ->
        templates = Map.get(@extension_templates, extension, [])

        create_views_and_templates(extension, templates, web_module, web_prefix)

        extension
      end)

    %{extensions: extensions, web_app: web_app, structure: structure}
  end

  defp create_views_and_templates(extension, [], _web_module, _web_prefix) do
    Mix.shell().info("Warning: No view or template files generated for #{inspect extension} as no templates has been defined for it.")
  end
  defp create_views_and_templates(extension, templates, web_module, web_prefix) do
    Enum.each(templates, fn {name, actions} ->
      Phoenix.create_view_file(extension, name, web_module, web_prefix)
      Phoenix.create_templates(extension, name, web_prefix, actions)
    end)
  end

  defp print_shell_instructions(%{extensions: [], web_app: web_app}) do
    Extension.no_extensions_error(web_app)
  end
  defp print_shell_instructions(config), do: config
end
