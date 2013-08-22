class TargetPrettifier
  def self.prettify(client, outputter)

    target = nil
    version = nil
    current_user_email = nil
    current_space_name = nil
    current_org_name = nil

    if client
      target = client.target
      version = client.version
      current_user = client.current_user
      current_space = client.current_space
      current_org = client.current_organization

      current_user_email = current_user.email if current_user
      current_space_name = current_space.name if current_space
      current_org_name = current_org.name if current_org
    end

    outputter.line("Target Information (where will apps be pushed):")
    outputter.line("  CF instance: #{print_var(target, outputter)} (API version: #{print_var(version, outputter)})")
    outputter.line("  user: #{print_var(current_user_email, outputter)}")
    outputter.line("  target app space: #{print_var(current_space_name, outputter)} (org: #{print_var(current_org_name, outputter)})")
  end

  def self.print_var(object_name, outputter)
    if object_name
      outputter.c(object_name, :good)
    else
      outputter.c('N/A', :bad)
    end
  end
end
