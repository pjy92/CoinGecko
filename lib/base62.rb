module Base62
  ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".freeze

  def self.encode(number)
    return "0" if number == 0

    result = ""
    while number > 0
      result = ALPHABET[number % 62] + result
      number /= 62
    end
    result
  end

  def self.decode(string)
    number = 0
    string.each_char do |char|
      number = number * 62 + ALPHABET.index(char)
    end
    number
  end
end
