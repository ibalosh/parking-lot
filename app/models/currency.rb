class Currency < ApplicationRecord
  validates :name, length: { minimum: 1, maximum: 255 }
  validates :code, length: { minimum: 1, maximum: 20 }
  validates :symbol, length: { is: 1 }
end
