# == Schema Information
#
# Table name: subscriber_activities
#
#  id               :integer          not null, primary key
#  subscriber_id    :integer
#  channel_id       :integer
#  message_id       :integer
#  type             :string(255)
#  origin           :string(255)
#  title            :text
#  caption          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  channel_group_id :integer
#  processed        :boolean
#  deleted_at       :datetime
#

class SubscriberActivity < ActiveRecord::Base
  acts_as_paranoid
  attr_accessible :caption, :origin, :title, :type, :tparty_identifier,:options

  serialize :options,Hash

  belongs_to :subscriber
  belongs_to :channel
  belongs_to :channel_group
  belongs_to :message

  before_validation :normalize_phone_number
  before_save :update_derived_attributes_before_save

  after_initialize do |sa|
    if sa.new_record?
      begin
        sa.processed ||= false
      rescue ActiveModel::MissingAttributeError
      end
    end
  end

  @child_classes = []

  def self.inherited(child)
    child.instance_eval do
      def model_name
        SubscriberActivity.model_name
      end
    end
    @child_classes << child
    super
  end

  def self.child_classes
    @child_classes
  end

  def self.of_subscriber(subscriber)
    where(subscriber_id:subscriber)
  end

  def self.of_subscribers(subscribers)
    where("subscriber_id in (?)",subscribers)
  end

  def self.for_message(message)
    where(message_id:message)
  end

  def self.for_messages(messages)
    where("message_id in (?)", messages)
  end

  def self.for_channel(channel)
    where(channel_id:channel)
  end

  def self.for_channels(channels)
    where("channel_id in (?)", channels)
  end 

  def self.for_channel_group(channel_group)
    where(channel_group_id:channel_group)
  end

  def self.for_channel_group_and_its_channels(channel_group)
    where("channel_group_id = ? or channel_id in (?)",channel_group,channel_group.channels)
  end

  def self.for_channel_groups(channel_groups)
    where("channel_group_id in (?)", channel_groups)
  end    

  def self.unprocessed
    where("processed=false")
  end

  def self.after(my_datetime)
    where("created_at > ?", my_datetime)
  end

  def parent_type
    if message
      :message
    elsif subscriber
      :subscriber
    elsif channel
      :channel
    elsif channel_group
      :channel_group
    end
  end

  def process
    raise NotImplementedError
  end


private
  def normalize_phone_number
    self.origin = Subscriber.format_phone_number(origin)
  end

  def update_derived_attributes_before_save
    self.channel = Channel.find(message.channel) if !channel && message
  end
end