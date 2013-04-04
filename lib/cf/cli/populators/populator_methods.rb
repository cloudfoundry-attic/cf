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
        info[type] = obj.guid
        save_target_info(info)
        invalidate_client

        obj
      end

      private

      def get_object
        if input.has?(type)
          object = input[type]
          with_progress("Switching to #{type} #{c(object.name, :name)}") {}
        elsif info[type]
          previous_object = client.send(type, (info[type]))
          object = previous_object if valid?(previous_object)
        end

        object || prompt_user
      end

      def prompt_user
        object_choices = choices

        if object_choices.empty?
          raise CF::UserFriendlyError.new(
            "There are no #{type}s. You may want to create one with #{c("create-#{type}", :good)}."
          )
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