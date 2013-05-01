require "cf/cli/space/base"

module CF::Space
  class Delete < Base
    desc "Delete a space and its contents"
    group :spaces
    input :organization, :desc => "Space's organization",
      :aliases => ["--org", "-o"], :from_given => by_name(:organization),
      :default => proc { client.current_organization }
    input :space, :desc => "Space to delete", :argument => true,
      :from_given => space_by_name
    input :recursive, :desc => "Delete recursively", :alias => "-r",
      :default => false, :forget => true
    input :warn, :desc => "Show warning if it was the last space",
      :default => true
    input :really, :type => :boolean, :forget => true, :hidden => true,
      :default => proc { force? || interact }

    def delete_space
      space = input[:space, org]

      return unless input[:really, space]

      deleting_current_space = (space == client.current_space)

      with_progress("Deleting space #{c(space.name, :name)}") do
        if input[:recursive]
          space.delete!(:recursive => true)
        else
          space.delete!
        end
      end

      if deleting_current_space
        line
        line c("The space that you were targeting has now been deleted. Please use #{b("`cf target -s SPACE_NAME`")} to target a different one.", :warning)
      end
    rescue CFoundry::AssociationNotEmpty => boom
      line
      line c(boom.description, :bad)
      line c("If you want to delete the space along with all dependent objects, rerun the command with the #{b("'--recursive'")} flag.", :bad)
      exit_status(1)
    end

    private

    def ask_really(space)
      ask("Really delete #{c(space.name, :name)}?", :default => false)
    end

    def ask_recursive
      ask "Delete #{c("EVERYTHING", :bad)}?", :default => false
    end
  end
end
