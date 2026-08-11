module PlatformCore
  # The kernel's PUBLIC registry of admin sections.
  #
  # The admin area is ONE page (/admin) made of stacked sections. The kernel owns
  # the page but must not know which modules exist, so the dependency is
  # inverted: each module registers its own section from its engine and the
  # dashboard just renders whatever is in the registry. Nothing here references a
  # module constant.
  #
  # Register from the engine's `to_prepare` block (re-runs on reload, so the
  # registry survives code reloading):
  #
  #   config.to_prepare do
  #     PlatformCore::AdminSections.register(
  #       key: "restaurants", label: "Restaurants", module_key: "restaurants",
  #       description: "Add spots and manage their photos.", position: 30
  #     ) { |params| Restaurants::Admin::SectionComponent.new(params: params) }
  #   end
  #
  # The block is called at render time with the request's params: resolving the
  # component class lazily keeps this reload-safe, and passing params lets a
  # section read its own filter/search values off the shared page URL.
  module AdminSections
    Section = Struct.new(:key, :label, :description, :module_key, :position, :builder, keyword_init: true) do
      def component(params)
        builder.call(params)
      end

      # The id/fragment used by the page's jump nav and by post-action redirects.
      def anchor
        "section-#{key}"
      end
    end

    module_function

    def register(key:, label:, description: nil, module_key: nil, position: 100, &builder)
      raise ArgumentError, "admin section #{key} needs a component block" unless builder

      registry[key.to_s] = Section.new(
        key: key.to_s, label: label, description: description,
        module_key: module_key&.to_s, position: position, builder: builder
      )
    end

    # Sections belonging to a switched-off module are hidden, so the page never
    # renders a surface whose routes BaseController would refuse to serve.
    def all
      registry.values
              .select { |section| section.module_key.nil? || PlatformCore::Modules.enabled?(section.module_key) }
              .sort_by { |section| [section.position, section.label] }
    end

    def registry
      @registry ||= {}
    end
  end
end
