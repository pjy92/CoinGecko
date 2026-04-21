module Base62
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def self.encode(num)
    return ALPHABET[0] if num == 0

    s = ""
    while num > 0
      s = ALPHABET[num % 62] + s
      num /= 62
    end
    s
  end
end
