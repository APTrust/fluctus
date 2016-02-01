class PhoneFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if not value =~ /^([0-9\.+ -]+)$/i
      record.errors.add(attribute, 'should only contain digits, period, plus sign, hyphen, and spaces')
    end
    if value.gsub(/\D/, '').length > 10
      record.errors.add(attribute, 'contains more than 10 numbers.  Please fix.')
    end
    if value.gsub(/\D/, '').length < 10
      record.errors.add(attribute, 'contains fewer than 10 numbers.  Please fix.')
    end
  end
end