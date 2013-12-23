module UsersHelper
  # Returns the Gravatar (http://gravatar.com/) for the given user.
  def gravatar_for(user, options = { size: 50 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{options[:size]}"
    image_tag(gravatar_url, alt: user.name, class: "gravatar")
  end

  # Returns a list of roles we have permission to assign
  def roles_for_select
     Role.all.select {|role| can? :add_user, role }.sort.map {|r| [r.name.titleize, r.id] }
  end
  def institutions_for_select
     Institution.all.select {|institution| can? :add_user, institution }
  end
end
