# app/services/card_validation_service.rb
class CardValidationService
  def self.luhn_valid?(card_number)
    return false if card_number.blank?
    
    clean_number = card_number.gsub(/[\s-]/, '')
    
    # Check if it's all zeros or doesn't match card number patterns
    return false if clean_number.match?(/\A0+\z/)
    return false unless clean_number.match?(/\A\d{13,19}\z/)
    
    sum = 0
    double = false
    
    # Process from right to left
    clean_number.reverse.chars.each do |char|
      digit = char.to_i
      
      if double
        digit *= 2
        digit -= 9 if digit > 9
      end
      
      sum += digit
      double = !double
    end
    
    sum % 10 == 0
  end

  def self.detect_card_type(card_number)
    return 'Invalid' if card_number.blank?
    
    clean_number = card_number.gsub(/[\s-]/, '')
    
    # Return 'Unknown' for all-zero cards
    return 'Unknown' if clean_number.match?(/\A0+\z/)
    
    case clean_number[0]
    when '4' then 'Visa'
    when '5' then 'MasterCard'
    when '3' then 'American Express'
    when '6' then 'Discover'
    else 'Unknown'
    end
  end

  def self.validate_card(card_number)
    {
      valid: luhn_valid?(card_number),
      card_type: detect_card_type(card_number),
      formatted: card_number.gsub(/(\d{4})(?=\d)/, '\1 ')
    }
  end
end