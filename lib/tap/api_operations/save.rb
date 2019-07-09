# frozen_string_literal: true

module Tap
  module APIOperations
    module Save
      module ClassMethods
        def update(id, params = {}, opts = {})
          params.each_key do |k|
            if protected_fields.include?(k)
              raise ArgumentError, "Cannot update protected field: #{k}"
            end
          end

          resp, opts = request(:put, "#{resource_url}/#{id}", params, opts)
          Util.convert_to_tap_object(resp.data, opts)
        end
      end

      def save(params = {}, opts = {})
        update_attributes(params)
        params = params.reject { |k, _| respond_to?(k) }
        values = serialize_params(self).merge(params)
        values.delete(:id)

        resp, opts = request(:put, save_url, values, opts)
        initialize_from(resp.data, opts)
      end

      def self.included(base)
        base.additive_object_param(:metadata)
        base.extend(ClassMethods)
      end

      private

      def save_url
        if self[:id].nil? && self.class.respond_to?(:create)
          self.class.resource_url
        else
          resource_url
        end
      end
    end
  end
end
