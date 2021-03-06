class HoursEntry < ActiveRecord::Base
  validates :amount, :organization, :contact_name, :contact_phone, :contact_email, presence: true, :if => :user_entered?
  validates :contact_email, :format => { :with => /\A[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})\z/, :message => "is not a valid email" }, :if => :user_entered?
  validates_numericality_of :amount, greater_than: 0, :if => :user_entered?

  before_save :send_verified_email

  belongs_to :user
  belongs_to :bid

  scope :earned, -> { where('amount > ? AND verified = ?', 0, true) }
  scope :used, -> { where('amount < 0') }

  def earned?
    amount > 0
  end

  def amount_in_words
    "#{amount} volunteer #{'hour'.pluralize(amount)}"
  end

  private

  def user_entered?
    user_entered
  end

  def send_verified_email
    HoursEntryMailer.verified(self).deliver if newly_verified?
  end

  def newly_verified?
    verified && verified_changed?
  end
end


