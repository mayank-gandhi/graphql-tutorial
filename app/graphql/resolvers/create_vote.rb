class Resolvers::CreateVote < GraphQL::Function
  # arguments passed as "args"
  argument :linkId, types.ID

  # return type from the mutation
  type Types::VoteType

  # the mutation method
  # _obj - is parent object, which in this case is nil
  # args - are the arguments passed
  # _ctx - is the GraphQL context (which would be discussed later)
  def call(_obj, args, ctx)
    Vote.create!(
      link: Link.find_by(id: args[:linkId]),
      user: ctx[:current_user]
    )
  end
end
