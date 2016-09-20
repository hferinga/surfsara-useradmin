class Invite < ApplicationRecord
  class Accept < Operation
    include Model
    model Invite, :find

    contract do
      property :accept_terms_of_service, virtual: true

      validate :accept_terms_of_service do
        errors.add(:accept_terms_of_service, :not_accepted) if accept_terms_of_service != '1'
      end
    end

    def process(params)
      validate(params[:invite]) do
        update_open_nebula
        update_invite
      end
    end

    private

    def model!(params)
      invite_token = InviteToken.new(params[:id])
      Invite.find_by!(accepted_at: nil, token: invite_token.encrypted)
    end

    private

    def update_open_nebula
      user = OneClient.find_user(current_user.one_username)
      user = OneClient.create_user(current_user.one_username, current_user.one_password) if user.nil?
      OneClient.add_user_to_group(user.id, @model.group_id) unless user.group_ids.include?(@model.group_id)
    end

    def update_invite
      @model.accepted_at = Time.current
      @model.accepted_by = current_user.one_username
      @model.save
    end

    def current_user
      @params[:current_user]
    end
  end
end
