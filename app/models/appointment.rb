# September 21, 2025
class Appointment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  enum :status, { scheduled: 0, canceled: 1, completed: 2 }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate :start_before_end
  validate :within_availability_window
  validate :no_overlapping_appointments

  scope :active, -> { where(status: :scheduled) }
  scope :overlapping, ->(starts_at, ends_at) {
    where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
  }

  def soft_cancel!
    update!(status: :canceled, canceled_at: Time.current)
  end

  private

  def start_before_end
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after start time") unless starts_at < ends_at
  end

  def within_availability_window
    return if starts_at.blank? || ends_at.blank?

    search = AvailabilitySearch.new(provider: provider)
    available_slots = search.call(from: starts_at, to: ends_at)

    covers_appointment = available_slots.any? do |slot|
      slot_start = Time.iso8601(slot[:start])
      slot_end = Time.iso8601(slot[:end])
      slot_start <= starts_at && ends_at <= slot_end
    end

    errors.add(:base, "Appointment must be within provider's available hours") unless covers_appointment
  end

  def no_overlapping_appointments
    return if starts_at.blank? || ends_at.blank?

    overlapping = provider.appointments.active
                         .where.not(id: id)
                         .overlapping(starts_at, ends_at)

    errors.add(:base, "Appointment conflicts with existing booking") if overlapping.exists?
  end
end
