class Url < ApplicationRecord
  has_many :url_visits, dependent: :destroy

  validates :original_url, presence: true
  validates :short_code, presence: true, uniqueness: true, length: { maximum: 15 }
end
