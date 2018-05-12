# frozen_string_literal: true

# This was an attempt to fix introspection queries taking up boatloads of complexity.
# it failed.

# module GraphQL
#   class Field
#     def complexity=(something)
#       "You lose"
#       nil
#     end
#
#     def complexity
#       @real_complexity || 0
#     end
#
#     def real_complexity=(complexity)
#       @real_complexity = complexity
#     end
#
#     def initialize
#       @real_complexity = 0
#       @complexity = 0
#       @arguments = {}
#       @resolve_proc = build_default_resolver
#       @lazy_resolve_proc = DefaultLazyResolve
#       @relay_node_field = false
#       @connection = false
#       @connection_max_page_size = nil
#       @edge_class = nil
#       @trace = nil
#       @introspection = false
#     end
#   end
#
#   class Function
#     def self.complexity
#       self.class.complexity || 0
#     end
#   end
# end

# module GraphQL
#   class Field
#     def initialize
#       @complexity = 1
#       @arguments = {}
#       @resolve_proc = build_default_resolver
#       @lazy_resolve_proc = DefaultLazyResolve
#       @relay_node_field = false
#       @connection = false
#       @connection_max_page_size = nil
#       @edge_class = nil
#       @trace = nil
#       @introspection = false
#     end
#   end
# end

# Logging of query complexity
log_query_complexity = GraphQL::Analysis::QueryComplexity.new { |_query, complexity| Rails.logger.info("[GraphQL Query Complexity] #{complexity}") }
MetasmokeSchema.query_analyzers << log_query_complexity
