# frozen_string_literal: true

UIDInput = GraphQL::InputObjectType.define do
  name "UID"
  argument :site, types.String
  argument :id, types.ID
end

Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  field :post do
    type Types::PostType
    argument :id, types.ID
    argument :uid, types.ID
    argument :site, types.String
    resolve ->(_obj, args, _ctx) do
      if args['link'] || args['links']
        Post.find(link: args['link'])
      elsif args['uid'] && args['site']
        Post.includes(:site).find_by(sites: {api_parameter: args['site']}, native_id: args['uid'])
      elsif args['id']
        Post.find(args['id'])
      else
        Post.last
      end
    end
  end

  field :posts do
    type types[Types::PostType]
    argument :ids, types[types.ID]
    argument :uids, types[types.String]
    argument :links, types[types.String]
    argument :last, types.Int
    argument :first, types.Int
    argument :offset, types.Int, default_value: 0
    description 'Find a Post by ID'
    resolve ->(_obj, args, _ctx) do
      posts = Post.all
      if args['links']
        posts = posts.where(link: args['links'])
      end
      if args['uids']
        all_sites = Site.all.select(:id, :api_parameter).map { |site| [site.id, site.api_parameter]}
        uids = args['uids'].map do |uid|
          site, native_id = uid.split(':')
          site_id = all_sites.select { |site_id, api_parameter| api_parameter == site }[0][0]
          [site_id, native_id].map(&:to_i)
        end
        all_permutations = posts.where(site_id: uids.map(&:first), native_id: uids.map(&:last))
        puts uids.to_s
        posts = uids.map do |site_id, native_id|
          all_permutations.select do |post|
            puts post.inspect
            puts "SiteID: #{site_id} NativeID: #{native_id}"
            post.site_id == site_id && post.native_id == native_id
          end.first
        end
        posts = Post.where(id: posts.map(&:id))
      end
      if args['ids']
        posts = posts.find(args['ids'])
      end
      return GraphQL::ExecutionError.new("You can't use 'last' and 'first' together") if args['first'] && args['last']
      if args['first']
        posts = posts.offset(args['offset']).first(args['first'])
      end
      if args['last']
        posts = posts.reverse_order.offset(args['offset']).first(args['last'])
      end
      post = posts.limit(100) if post.respond_to? :limit
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
