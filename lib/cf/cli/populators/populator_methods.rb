module CF
  module Populators
    module PopulatorMethods
      def self.included(klass)
        klass.class_eval do
          define_method(:type) do
            klass.name.split("::").last.downcase.to_sym
          end
        end
      end

      def populate_and_save!
        obj = get_object
        info[type] = obj.guid unless obj.nil?
        save_target_info(info)
        invalidate_client

        obj
      end

      private

      def get_object
        previous_object = client.send(type, (info[type])) if info[type]

        if input.has?(type)
          if respond_to?(:finder_argument, true)
            object = input[type, finder_argument]
          else
            object = input[type]
          end

          with_progress("Switching to #{type} #{c(object.name, :name)}") {}
        elsif info[type]
          object = previous_object if valid?(previous_object)
        end

        object ||= prompt_user

        if (previous_object != object) && respond_to?(:changed, true)
          changed
        end

        object
      end

      def prompt_user
        object_choices = choices

        if object_choices.empty?
          with_progress("There are no #{type}s. You may want to create one with #{c("create-#{type == :organization ? "org" : type}", :good)}.") {}
        elsif object_choices.is_a?(String)
          raise CF::UserFriendlyError.new(object_choices)
        elsif object_choices.size == 1 && !input.interactive?(type)
          object_choices.first
        else
          ask(type.to_s.capitalize, :choices => object_choices.sort_by(&:name), :display => proc(&:name)).tap do |object|
            with_progress("Switching to #{type} #{c(object.name, :name)}") {}
          end
        end
      end
    end
  end
end
