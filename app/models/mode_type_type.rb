class ModeTypeType < ActiveRecord::Type::String
  def cast(value)
    return if value.nil?
    return value if value.is_a?(ModeType)
    raise TypeError unless value.is_a?(String) || value.is_a?(Symbol)

    ModeType.find_by_key(value) || (raise ArgumentError)
  end

  def serialize(value)
    return if value.nil?
    raise TypeError unless value.is_a?(ModeType)

    value.key
  end
end
