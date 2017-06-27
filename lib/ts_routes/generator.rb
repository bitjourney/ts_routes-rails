# frozen_string_literal: true

require 'rails/application'

module TsRoutes
  class Generator

    FILTERED_DEFAULT_PARTS = [:controller, :action, :subdomain]
    URL_OPTIONS = [:protocol, :domain, :host, :port, :subdomain]

    DEFAULT_FILE_HEADER = "/* tslint:disable */"

    # @return [ActionDispatch::Routing::RouteSet]
    attr_reader :routes

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

    def initialize(routes: Rails.application.routes,
                   camel_case: true,
                   route_suffix: 'path',
                   include: nil,
                   exclude: nil,
                   header: DEFAULT_FILE_HEADER
                   )
      @routes = routes
      @camel_case = camel_case
      @route_suffix = route_suffix
      @include = include
      @exclude = exclude
      @header = header
    end

    # @return [ActionDispatch::Routing::RouteSet::NamedRouteCollection]
    def named_routes
      routes.named_routes
    end

    # @return [String] TypeScript source code that represents routes.ts
    def generate
      functions = named_routes.flat_map do |_name, route|
        build_routes_if_match(route) + mounted_app_routes(route)
      end

      header + "\n" + runtime_ts + "\n" + functions.join("\n")
    end

    # @param [ActionDispatch::Journey::Route] route
    def mounted_app_routes(route)
      app = route.app.respond_to?(:app) && route.app.respond_to?(:constraints) ? route.app.app : route.app

      if app.respond_to?(:superclass) && app.superclass <= Rails::Engine && !route.path.anchored
        app.routes.named_routes.flat_map do |_, engine_route|
          build_routes_if_match(engine_route, route)
        end
      else
        []
      end
    end

    # @param [ActionDispatch::Journey::Route] route
    # @param [ActionDispatch::Journey::Route] parent_route
    # @return [Array<String>]
    def build_routes_if_match(route, parent_route = nil)
      return [] if exclude && any_match?(route, parent_route, exclude)
      return [] if include && !any_match?(route, parent_route, include)

      [build_route_function(route, parent_route)]
    end

    def any_match?(route, parent_route, matchers)
      full_route = [parent_route&.name, route.name].compact.join('_')
      matchers.any? { |pattern| full_route =~ pattern }
    end

    # @param [ActionDispatch::Journey::Route] route
    # @param [ActionDispatch::Journey::Route] parent_route
    def build_route_function(route, parent_route = nil)
      route_name = build_route_name(parent_route&.name, route.name, route_suffix)

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

    # @return [String]
    def serialize(route, spec, parent_route)
      return nil unless spec
      return spec.tr(':', '').to_json if spec.is_a?(String)

      expr = serialize_spec(route, spec)
      if parent_route
        "#{serialize_spec(parent_route, parent_route.path.spec, nil)} + #{expr}"
      else
        expr
      end
    end

    # @param [ActionDispatch::Journey::Route] route
    # @param [ActionDispatch::Journey::Nodes::Node] spec
    # @param [ActionDispatch::Journey::Route] parent_route
    # @return [String]
    def serialize_spec(route, spec, parent_route = nil)
      case spec.type
      when :CAT
        "#{serialize(route, spec.left, parent_route)} + #{serialize(route, spec.right, parent_route)}"
      when :GROUP # to declare optional parts
        if (symbol = spec.left.find(&:symbol?))
          name_expr = serialize(route, spec.left, parent_route)
          %{($hasPresentOwnProperty(options, #{symbol.name.to_json}) ? #{name_expr} : "")}
        else
          serialize(route, spec.left, parent_route)
        end
      when :SYMBOL
        name = spec.name
        route.required_parts.include?(name.to_sym) ? name : "(options as any).#{name}"
      when :STAR
        name = spec.left.left.sub(/^\*/, '')
        %{#{name}.map((part) => $encode(part)).join("/")}
      when :LITERAL, :SLASH, :DOT
        serialize(route, spec.left, parent_route)
      else
        raise "Node type #{spec.type} is not supported yet"
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
