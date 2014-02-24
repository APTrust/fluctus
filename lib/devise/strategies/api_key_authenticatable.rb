# This blog post was helpful:
# http://kyan.com/blog/2013/10/11/devise-authentication-strategies

module Devise
  module Strategies
    class ApiKeyAuthenticatable < Base

      include ApiAuth

      def valid?
        api_request?
      end

      def authenticate!
        user = User.where(email: params[:user][:email]).first

        unless user
          fail! 
          return
        end

        user.valid_api_key?(params[:user][:api_secret_key]) ? success!(user) : fail!
      end

    end
  end
end

