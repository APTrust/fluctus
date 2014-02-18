module ApiAuth

protected

  # Determine whether or not a request should be handled as
  # an API request instead of a UI/browser request.
  def api_request?
    request.format.json? && params['user'] && params['user']['email'] && params['user']['api_secret_key']
  end

end
