class Provider < ApplicationRecord
  has_many :availabilities
  has_many :appointments

  validates :first_name, :last_name, :email, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  normalizes :email, with: ->(e) { e.strip.downcase }
end
