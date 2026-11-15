# Plain ActiveModel objects for FormBuilder specs (no database).
class TestCrewMember
  include ActiveModel::Model
  attr_accessor :name
  validates :name, presence: true

  def self.model_name = ActiveModel::Name.new(self, nil, "CrewMember")
end

class TestShip
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :callsign, :string
  attribute :email, :string
  attribute :password, :string
  attribute :bio, :string
  attribute :tonnage, :integer
  attribute :role, :string
  attribute :shields, :boolean, default: false
  attribute :heading, :string
  attribute :power, :integer, default: 40
  attribute :photo
  attribute :launched_on, :date

  attr_writer :crew

  validates :callsign, presence: true, length: { minimum: 3 }
  validates :email, presence: true, format: { with: /@/ }
  validates :tonnage, numericality: { greater_than: 0 }, allow_nil: true
  validates :role, inclusion: { in: %w[explorer freighter] }, allow_blank: true

  def self.model_name = ActiveModel::Name.new(self, nil, "Ship")

  def crew_attributes=(attrs)
    self.crew = attrs.values.map { |a| TestCrewMember.new(a) }
  end

  def crew = (@crew ||= [ TestCrewMember.new(name: "Ada"), TestCrewMember.new(name: "") ])
  def persisted? = false
end
