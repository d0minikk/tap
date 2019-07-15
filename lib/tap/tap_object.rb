# frozen_string_literal: true

module Tap
  class TapObject
    include Enumerable

    @@permanent_attributes = Set.new([:id])

    def self.additive_object_param(name)
      @additive_params ||= Set.new
      @additive_params << name
    end

    def self.additive_object_param?(name)
      @additive_params ||= Set.new
      @additive_params.include?(name)
    end

    def initialize(id = nil, opts = {})
      id, @retrieve_params = Util.normalize_id(id)
      @opts = Util.normalize_opts(opts)
      @original_values = {}
      @values = {}
      @unsaved_values = Set.new
      @transient_values = Set.new
      @values[:id] = id if id
    end

    def self.construct_from(values, opts = {})
      values = Tap::Util.symbolize_names(values)
      new(values[:id]).send(:initialize_from, values, opts)
    end

    def ==(other)
      other.is_a?(TapObject) && @values == other.instance_variable_get(:@values)
    end

    def eql?(other)
      self == other
    end

    def hash
      @values.hash
    end

    def deleted?
      @values.fetch(:deleted, false)
    end

    def to_s(*_args)
      JSON.pretty_generate(to_hash)
    end

    def inspect
      id_string = respond_to?(:id) && !id.nil? ? " id=#{id}" : ''
      "#<#{self.class}:0x#{object_id.to_s(16)}#{id_string}> JSON: " + JSON.pretty_generate(@values)
    end

    def update_attributes(values, opts = {}, dirty: true)
      values.each do |k, v|
        add_accessors([k], values) unless metaclass.method_defined?(k.to_sym)
        @values[k] = Util.convert_to_tap_object(v, opts)
        dirty_value!(@values[k]) if dirty
        @unsaved_values.add(k)
      end
    end

    def [](k)
      @values[k.to_sym]
    end

    def []=(k, v)
      send(:"#{k}=", v)
    end

    def keys
      @values.keys
    end

    def values
      @values.values
    end

    def to_json(*_a)
      JSON.generate(@values)
    end

    def as_json(*a)
      @values.as_json(*a)
    end

    def to_hash
      maybe_to_hash = lambda do |value|
        value && value.respond_to?(:to_hash) ? value.to_hash : value
      end

      @values.each_with_object({}) do |(key, value), acc|
        acc[key] = case value
                   when Array
                     value.map(&maybe_to_hash)
                   else
                     maybe_to_hash.call(value)
                   end
      end
    end

    def each(&blk)
      @values.each(&blk)
    end

    def dirty!
      @unsaved_values = Set.new(@values.keys)
      @values.each_value do |v|
        dirty_value!(v)
      end
    end

    def marshal_dump
      opts = @opts.clone
      opts.delete(:client)
      [@values, opts]
    end

    def marshal_load(data)
      values, opts = data
      initialize(values[:id])
      initialize_from(values, opts)
    end

    def serialize_params(options = {})
      update_hash = {}

      @values.each do |k, v|
        unsaved = @unsaved_values.include?(k)
        if options[:force] || unsaved || v.is_a?(TapObject)
          update_hash[k.to_sym] =
            serialize_params_value(@values[k], @original_values[k], unsaved, options[:force], key: k)
        end
      end

      update_hash.reject! { |_, v| v.nil? }
      update_hash
    end

    def self.protected_fields
      []
    end

    protected

    def metaclass
      class << self; self; end
    end

    def remove_accessors(keys)
      protected_fields = self.class.protected_fields

      metaclass.instance_eval do
        keys.each do |k|
          next if protected_fields.include?(k)
          next if @@permanent_attributes.include?(k)

          [k, :"#{k}=", :"#{k}?"].each do |method_name|
            remove_method(method_name) if method_defined?(method_name)
          end
        end
      end
    end

    def add_accessors(keys, values)
      protected_fields = self.class.protected_fields

      metaclass.instance_eval do
        keys.each do |k|
          next if protected_fields.include?(k)
          next if @@permanent_attributes.include?(k)

          if k == :method
            define_method(k) { |*args| args.empty? ? @values[k] : super(*args) }
          else
            define_method(k) { @values[k] }
          end

          define_method(:"#{k}=") do |v|
            if v == ''
              raise ArgumentError, "You cannot set #{k} to an empty string. " \
                "We interpret empty strings as nil in requests. " \
                "You may set (object).#{k} = nil to delete the property."
            end
            @values[k] = Util.convert_to_tap_object(v, @opts)
            dirty_value!(@values[k])
            @unsaved_values.add(k)
          end

          if [FalseClass, TrueClass].include?(values[k].class)
            define_method(:"#{k}?") { @values[k] }
          end
        end
      end
    end

    def method_missing(name, *args)
      if name.to_s.end_with?('=')
        attr = name.to_s[0...-1].to_sym
        val = args.first
        add_accessors([attr], attr => val)

        begin
          mth = method(name)
        rescue NameError
          raise NoMethodError, "Cannot set #{attr} on this object. HINT: you can't set: #{@@permanent_attributes.to_a.join(', ')}"
        end
        return mth.call(args[0])
      elsif @values.key?(name)
        return @values[name]
      end

      begin
        super
      rescue NoMethodError => e
        raise unless @transient_values.include?(name)
        raise NoMethodError, e.message + ".  HINT: The '#{name}' attribute was set in the past, however.  It was then wiped when refreshing the object with the result returned by Tap's API, probably as a result of a save().  The attributes currently available on this object are: #{@values.keys.join(', ')}"
      end
    end

    def respond_to_missing?(symbol, include_private = false)
      @values && @values.key?(symbol) || super
    end

    def initialize_from(values, opts, partial = false)
      @opts = Util.normalize_opts(opts)
      @original_values = self.class.send(:deep_copy, values)

      removed = partial ? Set.new : Set.new(@values.keys - values.keys)
      added = Set.new(values.keys - @values.keys)

      remove_accessors(removed)
      add_accessors(added, values)

      removed.each do |k|
        @values.delete(k)
        @transient_values.add(k)
        @unsaved_values.delete(k)
      end

      update_attributes(values, opts, dirty: false)
      values.each_key do |k|
        @transient_values.delete(k)
        @unsaved_values.delete(k)
      end

      self
    end

    def serialize_params_value(value, original, unsaved, force, key: nil)
      if value.nil?
        ''
      elsif value.is_a?(APIResource)
        if !unsaved
          nil
        elsif value.respond_to?(:id) && !value.id.nil?
          value
        else
          raise ArgumentError, "Cannot save property `#{key}` containing an API resource."
        end

      elsif value.is_a?(Array)
        update = value.map { |v| serialize_params_value(v, nil, true, force) }
        update if update != serialize_params_value(original, nil, true, force)
      elsif value.is_a?(Hash)
        Util.convert_to_tap_object(value, @opts).serialize_params

      elsif value.is_a?(TapObject)
        update = value.serialize_params(force: force)
        if original && unsaved && key && self.class.additive_object_param?(key)
          update = empty_values(original).merge(update)
        end

        update

      else
        value
      end
    end

    private

    def self.deep_copy(obj)
      case obj
      when Array
        obj.map { |e| deep_copy(e) }
      when Hash
        obj.each_with_object({}) do |(k, v), copy|
          copy[k] = deep_copy(v)
          copy
        end
      when TapObject
        obj.class.construct_from(
          deep_copy(obj.instance_variable_get(:@values)),
          obj.instance_variable_get(:@opts).select do |k, _v|
            Util::OPTS_COPYABLE.include?(k)
          end
        )
      else
        obj
      end
    end
    private_class_method :deep_copy

    def dirty_value!(value)
      case value
      when Array
        value.map { |v| dirty_value!(v) }
      when TapObject
        value.dirty!
      end
    end

    def empty_values(obj)
      values = case obj
               when Hash         then obj
               when TapObject then obj.instance_variable_get(:@values)
               else
                 raise ArgumentError, "#empty_values got unexpected object type: #{obj.class.name}"
               end

      values.each_with_object({}) do |(k, _), update|
        update[k] = ''
      end
    end
  end
end
