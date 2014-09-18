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
        api_user = request.headers["X-Fluctus-API-User"]
        api_key = request.headers["X-Fluctus-API-Key"]
        user = User.find_by_email(api_user)
        unless user
          fail!
          return
        end
        authenticated = api_key.nil? == false && user.valid_api_key?(api_key)
        if authenticated
          # Give API user a long timeout
          user.set_session_timeout(Fluctus::Application::API_USER_SESSION_TIMEOUT)
        end
        authenticated ? success!(user) : fail!
      end

    end
  end
end
