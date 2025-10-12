class Currency < ApplicationRecord
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :code, presence: true, uniqueness: true, length: { minimum: 1, maximum: 20 }
  validates :symbol, presence: true, length: { is: 1 }
end
