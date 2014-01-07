class Auction < ActiveRecord::Base
  belongs_to :user
  has_many :rewards, :dependent => :destroy
  accepts_nested_attributes_for :rewards, :allow_destroy => true

  scope :not_approved, where("approved IS NULL OR approved = false")

  validates :title, :short_description, :description, :about, :target, :start, :end, :volunteer_end_date, :banner, :image, presence: true
  validate :start_date_later_than_today, :end_date_later_than_start, :volunteer_end_date_later_than_end, :hours_add_up_to_target

  s3_credentials_hash = {
    :access_key_id => ENV['AWS_ACCESS_KEY'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  }

  has_attached_file :banner, 
                    :styles => { :thumb => "300x225#", :display => "720x540#" },
                    :s3_credentials => s3_credentials_hash,
                    :bucket => "timeauction",
                    :default_url => "https://s3-us-west-2.amazonaws.com/timeauction/missing.png"

  has_attached_file :image,
                    :styles => { :thumb => "300x225#", :display => "720x540#" },
                    :s3_credentials => s3_credentials_hash,
                    :bucket => "timeauction",
                    :default_url => "https://s3-us-west-2.amazonaws.com/timeauction/missing.png"

  def to_param
    "#{id}-#{title.parameterize}"
  end

  def hours_raised
    self.rewards.inject(0) {|sum, reward| sum + reward.amount * reward.users.count }
  end

  def raised_percentage
    "#{(hours_raised.to_f / self.target * 100).round}%"
  end

  def status
    str = "<b>#{num_volunteers}</b> bidder#{'s' unless num_volunteers == 1} ⋅ "
    str += "<b>#{hours_raised}</b> hrs raised ⋅ "
    str += "<b>#{days_left_to_bid[0]}</b> #{days_left_to_bid[1]} left to bid"
    return str.html_safe
  end

  def rewards_ordered_by_lowest
    self.rewards.sort_by{ |r| r.amount }
  end

  def lowest_bid
    rewards_ordered_by_lowest.first.amount
  end

  def num_volunteers
    self.rewards.map {|reward| reward.users }.flatten.uniq.count
  end

  def hours_left_to_bid
    (self.end - Time.now).to_i / 60 / 60
  end

  def days_left_to_bid
    hours = hours_left_to_bid
    if hours < 48
      return [hours, "hour#{'s' unless hours == 1}"]
    else
      return [hours / 24, "days"]
    end
  end

  def average_bid
    hours_raised == 0 ? 0 : "%g" % (hours_raised.to_f / num_volunteers)
  end

  private

  def start_date_later_than_today
    if start.nil? || start < Date.today + 1 # plus one for some leniency and timezone issues
      errors.add(:start, "must be today or later")
    end
  end

  def end_date_later_than_start
    if self.end.nil? || self.end <= start
      errors.add(:end, "must be later than start date")
    end
  end

  def volunteer_end_date_later_than_end
    if volunteer_end_date.nil? || volunteer_end_date <= self.end
      errors.add(:volunteer_end_date, "must be later than auction end date")
    end
  end

  def hours_add_up_to_target
    if has_limited_reward? && sum_of_total_possible_reward_hours < target
      errors.add(:target, "target is too high given number of possible reward hours (#{sum_of_total_possible_reward_hours})")
    end
  end

  def has_limited_reward?
    self.rewards.select{ |r| r.limit_bidders != true }.empty?
  end

  def sum_of_total_possible_reward_hours
    self.rewards.inject(0){ |sum, reward| sum + reward.amount * reward.max }
  end
end
