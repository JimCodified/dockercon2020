class Category < ApplicationRecord
  has_many :article_categories
  has_many :articles, through: :article_categories, dependent: :destroy
  validates :name, presence: true, uniqueness: true
  validates :name, length: { minimum: 3, maximum: 25 }
end
