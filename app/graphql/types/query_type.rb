# frozen_string_literal: true

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :post do
    type Types::PostType
    argument :id, types.ID
    argument :uid, types.ID
    argument :site, types.String
    argument :link, types.String
    resolve lambda(_obj, args, _ctx) do
      return GraphQL::ExecutionError.new('Invalid argument grouping') if [['uid', 'site'], ['id'], ['link']].include? args
      if args['link']
        Post.find(link: args['link'])
      elsif args['uid'] && args['site']
        Post.includes(:site).find_by(sites: { api_parameter: args['site'] }, native_id: args['uid'])
      elsif args['id']
        Post.find(args['id'])
      else
        Post.last
      end
    end
  end

  field :posts do
    type types[Types::PostType]
    argument :ids, types[types.ID], "A list of Metasmoke IDs"
    argument :uids, types[types.String], "A list of on-site id and site name pairs, e.g. ['stackunderflow:12345', 'superloser:54321']"
    argument :links, types[types.String], "A list of links to posts"
    argument :last, types.Int, "Last n items from selection. Can be used in conjunction with any other options except 'first'"
    argument :first, types.Int, "First n items from selection. Can be used in conjunction with any other options except 'last'"
    argument :offset, types.Int, "Number of items to offset by. Offset counted from start unless the 'last' option is used, in which case offset is counted from the end.", default_value: 0
    description 'Find Posts, with a maximum of 100 to be returned'
    resolve lambda(_obj, args, _ctx) do
      posts = Post.all
      posts = posts.where(link: args['links']) if args['links']
      if args['uids']
        all_sites = Site.all.select(:id, :api_parameter).map { |site| [site.id, site.api_parameter] }
        uids = args['uids'].map do |uid|
          site, native_id = uid.split(':')
          site_id = all_sites.select { |_site_id, api_parameter| api_parameter == site }[0][0]
          [site_id, native_id].map(&:to_i)
        end
        all_permutations = posts.where(site_id: uids.map(&:first), native_id: uids.map(&:last))
        posts = uids.map do |site_id, native_id|
          all_permutations.select do |post|
            post.site_id == site_id && post.native_id == native_id
          end.first
        end
        posts = Post.where(id: posts.map(&:id))
      end
      posts = posts.find(args['ids']) if args['ids']
      return GraphQL::ExecutionError.new("You can't use 'last' and 'first' together") if args['first'] && args['last']
      posts = posts.offset(args['offset']).first(args['first']) if args['first']
      posts = posts.reverse_order.offset(args['offset']).first(args['last']) if args['last']
      posts = posts.limit(100) if post.respond_to? :limit
      Array(posts)
    end
  end

  field :feedback do
    type Types::FeedbackType
    argument :id, !types.ID
    description 'Find a Feedback by ID'
    resolve ->(_obj, args, _ctx) { Feedback.find(args['id']) }
  end

  field :smoke_detector do
    type Types::SmokeDetectorType
    argument :id, !types.ID
    description 'Find a SmokeDetector by ID'
    resolve ->(_obj, args, _ctx) { SmokeDetector.find(args['id']) }
  end

  field :site do
    type Types::SiteType
    argument :id, !types.ID
    description 'Find a Site by ID'
    resolve ->(_obj, args, _ctx) { Site.find(args['id']) }
  end

  field :stack_exchange_user do
    type Types::StackExchangeUserType
    argument :id, !types.ID
    description 'Find a StackExchangeUser by ID'
    resolve ->(_obj, args, _ctx) { StackExchangeUser.find(args['id']) }
  end

  field :announcement do
    type Types::StackExchangeUserType
    argument :id, !types.ID
    description 'Find a Announcement by ID'
    resolve ->(_obj, args, _ctx) { Announcement.find(args['id']) }
  end

  field :reason do
    type Types::ReasonType
    argument :id, !types.ID
    description 'Find a Reason by ID'
    resolve ->(_obj, args, _ctx) { Reason.find(args['id']) }
  end

  field :user do
    type Types::UserType
    argument :id, !types.ID
    description 'Find a User by ID'
    resolve ->(_obj, args, _ctx) { User.find(args['id']) }
  end

  # deletion_logs domain_tags flag_logs moderator_sites
end
