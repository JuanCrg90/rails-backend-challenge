class Availability < ApplicationRecord
  belongs_to :provider

  enum :day_of_week, {
    sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
    thursday: 4, friday: 5, saturday: 6
  }, validate: true

  validates :remote_id, presence: true, uniqueness: { scope: [ :provider_id, :source ] }
  validates :source, presence: true
  validates :starts_at_minute, :ends_at_minute,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  validate :starts_before_ends

  def starts_at=(hhmm)
    self.starts_at_minute = self.class.hhmm_to_minutes(hhmm)
  end

  def ends_at=(hhmm)
    self.ends_at_minute = self.class.hhmm_to_minutes(hhmm)
  end

  def starts_at_hhmm = self.class.minutes_to_hhmm(starts_at_minute)
  def ends_at_hhmm   = self.class.minutes_to_hhmm(ends_at_minute)

  def self.hhmm_to_minutes(hhmm)
    m = /\A(?<h>\d{2}):(?<m>\d{2})\z/.match(hhmm) or raise ArgumentError, "Invalid time: #{hhmm}"
    h = m[:h].to_i; mm = m[:m].to_i
    raise ArgumentError, "Invalid time: #{hhmm}" unless h.between?(0, 23) && mm.between?(0, 59)
    h * 60 + mm
  end

  def self.minutes_to_hhmm(mins)
    h = mins / 60
    m = mins % 60
    format("%02d:%02d", h, m)
  end

  private

  def starts_before_ends
    return if starts_at_minute.blank? || ends_at_minute.blank?
    errors.add(:base, "starts_at must be before ends_at") unless starts_at_minute < ends_at_minute
  end
end
