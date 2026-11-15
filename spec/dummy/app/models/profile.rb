# Plain ActiveModel profile for the dummy app's form demo (no database): kept in memory between requests.
class Profile
  include ActiveModel::Model
  include ActiveModel::Attributes

  ROLES = [ [ "Explorer", "explorer" ], [ "Freighter", "freighter" ], [ "Medic", "medic" ] ].freeze
  CONTACTS = [ [ "Comms", "comms" ], [ "Courier", "courier" ], [ "None", "none" ] ].freeze

  attribute :callsign, :string
  attribute :email, :string
  attribute :bio, :string
  attribute :role, :string
  attribute :shields, :boolean, default: false
  attribute :contact, :string
  attribute :clearance, :integer, default: 20
  attribute :birthday, :date
  attribute :avatar

  validates :callsign, presence: true, length: { in: 3..20 }
  validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, allow_blank: true }
  validates :bio, length: { maximum: 200 }
  validates :role, inclusion: { in: ROLES.map(&:last) }
  validates :contact, inclusion: { in: CONTACTS.map(&:last) }
  validates :clearance, numericality: { in: 0..100 }
  validates :birthday, presence: true

  class << self
    attr_accessor :stored

    def reset! = (self.stored = nil)
  end

  def persisted? = self.class.stored.present?
  def to_key = (persisted? ? [ 1 ] : nil)
end
