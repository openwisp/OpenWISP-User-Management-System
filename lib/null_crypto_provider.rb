class NullCryptoProvider
  def self.encrypt(*tokens)
    plain, salt = *tokens
    plain
  end

  def self.matches?(crypted, *tokens)
    plain, salt = *tokens
    plain == crypted
  end
end