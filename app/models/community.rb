class Community < ApplicationRecord
  belongs_to :organization
  has_many :units, dependent: :destroy

  validates :name, presence: true
  validates :tbk_child_commerce_code, presence: true
end
