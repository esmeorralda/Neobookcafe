module CacheVersion
  def self.key(name) = "v:#{name}"
  def self.get(name) = Rails.cache.fetch(key(name)) { 1 }
  def self.bump!(name) = Rails.cache.increment(key(name), 1, initial: 1)
end
