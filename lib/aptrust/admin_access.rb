module Aptrust::AdminAccess
  # Override hydra-access-controls so that admins aren't gated. 
  def apply_gated_discovery(solr_parameters, user_parameters)
    return if current_user && current_user.admin?
    super
  end

end
