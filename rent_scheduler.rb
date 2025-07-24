require 'date'

class RentScheduler
  PROCESSING_DAYS = {
    'instant' => 0,
    'credit_card' => 2,
    'bank_transfer' => 3
  }.freeze

  FREQUENCY_DAYS = {
    'weekly' => 7,
    'fortnightly' => 14,
  }.freeze

  def initialize(rent:, rent_changes: nil, max_occurrence: 12)
    raise ArgumentError, "Rent start date is required" unless rent[:start_date]
    raise ArgumentError, "Rent frequency should be weekly, monthly or fortnightly" unless FREQUENCY_DAYS.keys.include?(rent[:frequency]) || rent[:frequency] == "monthly"

    @base_amount = rent[:amount] || 0
    @frequency = rent[:frequency] || 'monthly'
    @start_date = Date.parse(rent[:start_date])
    @end_date = rent[:end_date] ? Date.parse(rent[:end_date]) : nil
    @payment_method = rent[:payment_method] || 'instant'
    
    rent_changes = [rent_changes] if rent_changes.is_a?(Hash)
    @rent_changes = rent_changes&.map { |rc| { date: Date.parse(rc[:effective_date]), amount: rc[:amount] } } || []
    
    @max_occurrences = max_occurrence
    @anchor_day = @start_date.day
  end

  def generate
    dates = generate_dates
    schedule = []

    dates.each do |date|
      amount = applicable_rent_amount(date)
      payment_date = date - PROCESSING_DAYS[@payment_method]
      schedule << {
        payment_date: payment_date.to_s,
        amount: amount,
        method: @payment_method
      }
    end

    schedule
  end

  private

  def generate_dates
    result = []
    current = @start_date
    count = 0

    while (@end_date.nil? || current < @end_date) && (count < @max_occurrences || @end_date)
      result << current
      current = current = @frequency == 'monthly' ? next_month_preserving_day(current, @anchor_day) : current + FREQUENCY_DAYS[@frequency]
      count += 1
    end

    result
  end
  # method for specific day or last day of the month which has leap year. for example, monthly then 31, 01-31 02-29, 03-31
  def next_month_preserving_day(date, anchor_day)
    next_month = date >> 1
    max_day = Date.new(next_month.year, next_month.month, -1).day
    Date.new(next_month.year, next_month.month, [anchor_day, max_day].min)
  end

  def applicable_rent_amount(date)
    changes = @rent_changes.select { |rc| rc[:date] <= date }
    if changes.empty?
      @base_amount
    else
      changes.max_by { |rc| rc[:date] }[:amount]
    end
  end
end
