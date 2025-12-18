Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  scope = opts[:scope]

  # Rotate JTI on login
  user.update_column(:jti, SecureRandom.uuid)
end

Warden::Manager.before_logout do |user, auth, opts|
  scope = opts[:scope]

  # Optional: rotate JTI on logout
  user.update_column(:jti, SecureRandom.uuid) if user
end
