# frozen_string_literal: true

class ApplicationStatistics
  PERIODS = {
    "4w" => { length: 4, unit: :weeks },
    "3m" => { length: 12, unit: :weeks },
    "12m" => { length: 12, unit: :months }
  }.freeze
  REPLIES = %w[interview offer rejected].freeze

  Bucket = Data.define(:label, :sent, :replies)

  def self.call(user, period)
    new(user, period).call
  end

  def initialize(user, period)
    @user = user
    @period = PERIODS.key?(period) ? period : "3m"
  end

  def call
    self
  end

  def period
    @period
  end

  def buckets
    @buckets ||= windows.map do |window|
      events = events_between(window[:start], window[:finish])
      Bucket.new(
        label: window[:label],
        sent: events.count { |event| event.to_status == "applied" },
        replies: events.count { |event| REPLIES.include?(event.to_status) }
      )
    end
  end

  def sent_total
    buckets.sum(&:sent)
  end

  def replies_total
    buckets.sum(&:replies)
  end

  def interviews_total
    period_events.count { |event| event.to_status == "interview" }
  end

  def offers_total
    period_events.count { |event| event.to_status == "offer" }
  end

  def max_count
    [ buckets.map { |bucket| [ bucket.sent, bucket.replies ].max }.max.to_i, 1 ].max
  end

  private

  def windows
    spec = PERIODS[@period]
    spec[:length].times.map do |index|
      age = spec[:length] - 1 - index
      if spec[:unit] == :months
        start = age.months.ago.beginning_of_month
        { start: start, finish: start.end_of_month, label: I18n.l(start.to_date, format: "%b") }
      else
        start = age.weeks.ago.beginning_of_week
        { start: start, finish: start.end_of_week, label: I18n.l(start.to_date, format: "%-d %b") }
      end
    end
  end

  def period_events
    @period_events ||= events_between(windows.first[:start], windows.last[:finish])
  end

  def events
    @events ||= @user.application_events.to_a
  end

  def events_between(start, finish)
    events.select { |event| event.created_at >= start && event.created_at <= finish }
  end
end
