require_relative 'rent_scheduler'
require 'minitest/autorun'

class RentSchedulerTest < Minitest::Test
  def test_missing_start_date_raises_error
    rent = {
      amount: 1000,
      frequency: 'monthly',
      end_date: '2024-04-01'
      # missing start_date
    }

    error = assert_raises(ArgumentError) do
      RentScheduler.new(rent: rent)
    end

    assert_equal "Rent start date is required", error.message
  end

  def test_scenario_1_basic_rent
    rent = {
      amount: 1000,
      frequency: 'monthly',
      start_date: '2024-01-01',
      end_date: '2024-04-01'
    }

    scheduler = RentScheduler.new(rent: rent)
    output = scheduler.generate

    expected = [
      { payment_date: '2024-01-01', amount: 1000, method: 'instant' },
      { payment_date: '2024-02-01', amount: 1000, method: 'instant' },
      { payment_date: '2024-03-01', amount: 1000, method: 'instant' }
    ]

    assert_equal expected, output
  end

  def test_scenario_2_with_rent_change
    rent = {
      amount: 1000,
      frequency: 'monthly',
      start_date: '2024-01-01',
      end_date: '2024-04-01'
    }

    rent_change = {
      amount: 1200,
      effective_date: '2024-02-15'
    }

    scheduler = RentScheduler.new(rent: rent, rent_changes: [rent_change])
    output = scheduler.generate

    expected = [
      { payment_date: '2024-01-01', amount: 1000, method: 'instant' },
      { payment_date: '2024-02-01', amount: 1000, method: 'instant' },
      { payment_date: '2024-03-01', amount: 1200, method: 'instant' }
    ]

    assert_equal expected, output
  end

  def test_scenario_3_with_credit_card
    rent = {
      amount: 1000,
      frequency: 'monthly',
      start_date: '2024-01-01',
      end_date: '2024-04-01',
      payment_method: 'credit_card'
    }

    scheduler = RentScheduler.new(rent: rent)
    output = scheduler.generate

    expected = [
      { payment_date: '2023-12-30', amount: 1000, method: 'credit_card' },
      { payment_date: '2024-01-30', amount: 1000, method: 'credit_card' },
      { payment_date: '2024-02-28', amount: 1000, method: 'credit_card' }
    ]

    assert_equal expected, output
  end
end
