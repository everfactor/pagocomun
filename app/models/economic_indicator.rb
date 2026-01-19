class EconomicIndicator < ApplicationRecord
  validates :kind, presence: true, inclusion: {in: %w[uf ipc]}
  validates :value, presence: true
  validates :date, presence: true, uniqueness: {scope: :kind}

  enum :kind, %w[uf ipc].index_by(&:itself), prefix: true

  scope :latest, ->(kind) { where(kind: kind).order(date: :desc).first }

  class << self
    def latest_uf
      ensure_fresh("uf")
      latest("uf")
    end

    def latest_ipc
      ensure_fresh("ipc")
      latest("ipc")
    end

    def snapshot
      uf = latest_uf
      ipc = latest_ipc

      {
        uf_value: uf&.value,
        ipc_value: ipc&.value,
        indicator_date: uf&.date || Date.current
      }
    end

    private

    def ensure_fresh(kind)
      CMF::IndicatorFetcher.call if stale?(kind)
    rescue => e
      Rails.logger.error "Auto-fetch failed for #{kind}: #{e.message}"
    end

    def stale?(kind)
      case kind
      when "uf"
        uf_stale?
      when "ipc"
        ipc_stale?
      end
    end

    def uf_stale?
      # On weekends, allow a 2-day margin
      range = Date.current.on_weekend? ? (Date.current - 2.days)..Date.current : Date.current
      !exists?(kind: "uf", date: range)
    end

    def ipc_stale?
      # Check current and previous month
      months = [Date.current.beginning_of_month, 1.month.ago.to_date.beginning_of_month]
      !exists?(kind: "ipc", date: months)
    end
  end
end
