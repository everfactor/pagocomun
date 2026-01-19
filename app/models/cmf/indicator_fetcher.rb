module CMF
  class IndicatorFetcher
    BASE_URL = "https://api.cmfchile.cl/api-sbifv3/recursos_api"

    def self.call
      new.call
    end

    def call
      fetch_uf
      fetch_ipc
    end

    def fetch_uf
      data = call_api("uf")
      return unless data && data["UFs"]

      data["UFs"].each do |uf_data|
        save_indicator("uf", uf_data["Valor"], uf_data["Fecha"], data)
      end
    end

    def fetch_ipc
      data = call_api("ipc")
      return unless data && data["IPCs"]

      data["IPCs"].each do |ipc_data|
        save_indicator("ipc", ipc_data["Valor"], ipc_data["Fecha"], data)
      end
    end

    private

    def call_api(resource)
      api_key = Rails.application.credentials.cmf_api_key
      return if api_key.blank?

      response = Faraday.get("#{BASE_URL}/#{resource}", {
        apikey: api_key,
        formato: "json"
      })

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error "CMF API error fetching #{resource}: #{response.status} #{response.body}"
        Rails.cache.write("cmf_sync_error_#{resource}", "HTTP #{response.status}", expires_in: 1.day)
        nil
      end
    rescue => e
      Rails.logger.error "CMF API exception fetching #{resource}: #{e.message}"
      Rails.cache.write("cmf_sync_error_#{resource}", e.message, expires_in: 1.day)
      nil
    end

    def save_indicator(kind, raw_value, date_str, raw_payload)
      # Value parsing: "39.739,42" -> 39739.42
      value = raw_value.delete(".").tr(",", ".").to_d
      date = Date.parse(date_str)

      indicator = EconomicIndicator.find_or_initialize_by(kind: kind, date: date)
      indicator.value = value
      indicator.source = "CMF"
      indicator.raw_payload = raw_payload
      indicator.save!

      Rails.cache.delete("cmf_sync_error_#{kind}")
    rescue => e
      Rails.logger.error "Error saving CMF indicator #{kind}: #{e.message}"
      Rails.cache.write("cmf_sync_error_#{kind}", e.message, expires_in: 1.day)
    end
  end
end
