class TargetPrettifier
  def self.prettify(client, outputter)
    outputter.line("Target Information (where will apps be pushed):")
    outputter.line("  CF instance: #{print_var(client.try(:target), outputter)} (API version: #{print_var(client.try(:version), outputter)})")
    outputter.line("  user: #{print_var(client.try(:current_user).try(:email), outputter)}")
    outputter.line("  target app space: #{print_var(client.try(:current_space).try(:name), outputter)} (org: #{print_var(client.try(:current_organization).try(:name), outputter)})")
  end

  def self.print_var(object_name, outputter)
    if object_name
      outputter.c(object_name, :good)
    else
      outputter.c('N/A', :bad)
    end
  end
end