require 'search_object/plugin/graphql'

class Resolvers::LinksSearch
  # include SearchObject for GraphQL
  include SearchObject.module(:graphql)

  # scope is starting point for search
  scope { Link.all }

  # return type
  type !types[Types::LinkType]

  # inline input type definition for the advance filter
  LinkFilter = GraphQL::InputObjectType.define do
    name 'LinkFilter'

    argument :OR, -> { types[LinkFilter] }
    argument :description_contains, types.String
    argument :url_contains, types.String
  end

  Pagination = GraphQL::InputObjectType.define do
    name 'Pagination'

    argument :page, types.Int
    argument :per_page, types.Int
  end

  # when "filter" is passed "apply_filter" would be called to narrow the scope
  option :filter, type: LinkFilter, with: :apply_filter
  option :pagination, type: Pagination, with: :apply_pagination

  def apply_pagination(scope, value)
    scope.paginate(page: value["page"], per_page: value["per_page"])
  rescue RangeError => e
    # this would catch all validation errors and translate them to GraphQL::ExecutionError
    GraphQL::ExecutionError.new("Invalid input: #{e.message}")
  end

  # apply_filter recursively loops through "OR" branches
  def apply_filter(scope, value)
    # normalize filters from nested OR structure, to flat scope list
    branches = normalize_filters(value).reduce { |a, b| a.or(b) }
    scope.merge branches
  end

  def normalize_filters(value, branches = [])
    # add like SQL conditions
    scope = Link.all
    scope = scope.where('description LIKE ?', "%#{value['description_contains']}%") if value['description_contains']
    scope = scope.where('url LIKE ?', "%#{value['url_contains']}%") if value['url_contains']

    branches << scope

    # continue to normalize down
    value['OR'].reduce(branches) { |s, v| normalize_filters(v, s) } if value['OR'].present?

    branches
  end
end
