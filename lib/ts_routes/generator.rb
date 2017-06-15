# frozen_string_literal: true

require 'rails/application'

module TsRoutes
  class Generator

    FILTERED_DEFAULT_PARTS = [:controller, :action, :subdomain]
    URL_OPTIONS = [:protocol, :domain, :host, :port, :subdomain]

    DEFAULT_FILE_HEADER = "/* tslint:disable:max-line-length variable-name whitespace */"

    # @return [Rails::Application]
    attr_reader :application

    # @return [Boolean] default to true
    attr_reader :camel_case

    # @return [String] default to 'path'
    attr_reader :route_suffix

    # @return [Array<Regexp>,nil] default to nil
    attr_reader :include

    # @return [Array<Regexp>,nil] default to nil
    attr_reader :exclude

    # @return [String]
    attr_reader :header

    def initialize(application: Rails.application,
                   camel_case: true,
                   route_suffix: 'path',
                   include: nil,
                   exclude: nil,
                   header: DEFAULT_FILE_HEADER
                   )
      @application = application
      @camel_case = camel_case
      @route_suffix = route_suffix
      @include = include
      @exclude = exclude
      @header = header
    end

    # @return [ActionDispatch::Routing::RouteSet]
    def routes
      application.routes
    end

    # @return [ActionDispatch::Routing::RouteSet::NamedRouteCollection]
    def named_routes
      routes.named_routes
    end

    # @return [String] TypeScript source code that represents routes.ts
    def generate
      functions = named_routes.flat_map do |_name, route|
        build_routes_if_match(route)
      end.compact

      header + "\n" + runtime_ts + "\n" + functions.join("\n")
    end

    # @param [ActionDispatch::Journey::Route] route
    # @param [ActionDispatch::Journey::Route] parent_route
    # @return [Array<String>,nil]
    def build_routes_if_match(route, parent_route = nil)
      return if exclude && any_match?(route, parent_route, exclude)
      return if include && !any_match?(route, parent_route, include)

      build_routes(route, parent_route)
    end

    def any_match?(route, parent_route, matchers)
      full_route = [parent_route&.name, route.name].compact.join('_')
      matchers.any? { |pattern| full_route =~ pattern }
    end

    # @param [ActionDispatch::Journey::Route] route
    # @param [ActionDispatch::Journey::Route] parent_route
    def build_routes(route, parent_route = nil)
      name_parts = [route.name, parent_route&.name].compact
      route_name = build_route_name(*name_parts, route_suffix)
      required_param_declarations = route.required_parts.map do |name|
        symbol = find_spec(route.path.spec, name)
        "#{name}: #{symbol.left.start_with?('*') ? "ScalarType[]" : "ScalarType"}, "
      end.join()
      path_expr = serialize(route, route.path.spec, parent_route)
      <<~TS
        /** #{parent_route&.path&.spec}#{route.path.spec} */
        export function #{route_name}(#{required_param_declarations}options?: object): string {
          return #{path_expr} + $buildOptions(options, #{route.path.names.to_json});
        }
      TS
    end

    # @param [Array<String>] name_parts
    def build_route_name(*name_parts)
      route_name = name_parts.compact.join('_')
      camel_case ? route_name.camelize(:lower) : route_name
    end

    def build_route_params_type_name(*name_parts)
      name_parts.join('_').camelize(:upper) + "ParamsType"
    end

    def serialize(route, spec, parent_spec = nil)
      return nil unless spec
      return spec.tr(':', '').to_json if spec.is_a?(String)
      result = serialize_spec(route, spec, parent_spec)
      if parent_spec && result[1].is_a?(String)
        result = [
            Operator.new("CAT"),
            serialize_spec(route, parent_spec),
            result
        ]
      end
      result
    end

    def serialize_spec(route, spec, parent_spec = nil)
      case spec.type
      when :CAT
        "#{serialize(route, spec.left, parent_spec)} + #{serialize(route, spec.right)}"
      when :GROUP
        name = find_symbol(spec.left).name
        name_expr = serialize(route, spec.left, parent_spec)
        %{((options && options.hasOwnProperty(#{name.to_json})) ? #{name_expr} : "")}
      when :SYMBOL
        name = spec.name
        route.required_parts.include?(name.to_sym) ? name : "(options as any).#{name}"
      when :STAR
        name = spec.left.left.sub(/^\*/, '')
        %{#{name}.map((part) => encodeURIComponent("" + part)).join("/")}
      when :LITERAL, :SLASH, :DOT
        serialize(route, spec.left, parent_spec)
      else
        "#{spec.type}(" +
            serialize(route, spec.left, parent_spec) +
            (spec.respond_to?(:right) ? ", #{serialize(route, spec.right)}" : "") +
            ")"
      end
    end

    # @param [ActionDispatch::Journey::Nodes::Node] node
    # @return [ActionDispatch::Journey::Nodes::Symbol]
    def find_symbol(node)
      if node.respond_to?(:symbol?) && node.symbol?
        node
      else
        if node.respond_to?(:left)
          find_symbol(node.left)&.tap do |symbol_node|
            return symbol_node
          end
        end
        if node.respond_to?(:right)
          find_symbol(node.right)&.tap do |symbol_node|
            return symbol_node
          end
        end
      end
    end

    # @param [ActionDispatch::Journey::Nodes::Node] node
    # @param [Symbol] name
    def find_spec(node, name)
      node.find do |n|
        n.symbol? && n.name == name.to_s
      end
    end

    def runtime_ts
      File.read(File.expand_path("runtime.ts", __dir__))
    end
  end
end
