require 'open-uri'
require 'json'
require 'open-uri'
require 'rubygems'
require 'bundler'
require 'active_support/core_ext'
require 'pp'
require 'net/http'
require 'digest/hmac'
require 'openssl'

class Wikimart

  API_PATH = '/api/1.0/'

  METHOD_GET    = 'GET'
  METHOD_POST   = 'POST'
  METHOD_PUT    = 'PUT'
  METHOD_DELETE = 'DELETE'

  STATUS_OPENED    = 'opened'
  STATUS_CANCELED  = 'canceled'
  STATUS_REJECTED  = 'rejected'
  STATUS_CONFIRMED = 'confirmed'
  STATUS_ANNULED   = 'annuled'
  STATUS_INVALID   = 'invalid'
  STATUS_FAKED     = 'faked'

  DATA_JSON        = 'json'
  DATA_XML         = 'xml'

  STATE_CREATED            = 'created'
  STATE_ACCEPTED           = 'accepted'
  STATE_ASSEMBLED          = 'assembled'
  STATE_PASSED_IN_DELIVERY = 'passed_in_delivery'
  STATE_IN_DELIVERY        = 'in_delivery'
  STATE_DELIVERED          = 'delivered'
  STATE_UNDELIVERED        = 'undelivered'
  STATE_CANCELLED          = 'cancelled'

  STATUS_PAYMENT_PENDING    = 'pending'
  STATUS_PAYMENT_HOLD       = 'hold'
  STATUS_PAYMENT_PAYED      = 'payed'
  STATUS_PAYMENT_REVERSED   = 'reversed'
  STATUS_PAYMENT_REFUSED    = 'refused'
  STATUS_PAYMENT_REFUND     = 'refund'

  @@host = 'http://merchant.wikimart.ru'
  @@app_id = ''
  @@app_secret = ''
  @@data_type = self::DATA_JSON

  def self.instance(host = nil, app_id = nil, app_secret = nil, data_type = self::DATA_JSON)

    @@instance ||= Wikimart.new

    if host.present?
      @@host = host
    end
    if app_id.present?
      @@app_id = app_id
    end
    if app_secret.present?
      @@app_secret = app_secret
    end
    if data_type.present?
      @@data_type = data_type
    end
    @@instance
  end

  def directory_order_statuses
    response Wikimart::API_PATH + 'directory/order/statuses'
  end

  def directory_delivery_variants
    response Wikimart::API_PATH + 'directory/delivery/variants/'
  end

  def directory_delivery_location delivery_id = nil
    response Wikimart::API_PATH + "directory/delivery/#{delivery_id}/location"
  end

  def directory_delivery_statuses
    response Wikimart::API_PATH + 'directory/delivery/statuses'
  end

  def directory_payment_types
    response Wikimart::API_PATH + 'directory/payment/types'
  end

  def directory_appeal_subject
    response Wikimart::API_PATH + 'directory/appeal/subject'
  end

  def order_list status = Wikimart::STATUS_OPENED, date_from = DateTime.now - 1.week, date_to = DateTime.now,
                 transition_status =  Wikimart::STATUS_OPENED, page = 1, page_size = 100, appeal_status = ''

    params = {
        :status => status,
        :transitionDateFrom => date_from.to_time.iso8601,
        :transitionDateTo => date_to.to_time.iso8601,
        :transitionStatus => transition_status,
        :page => page.to_s,
        :pageSize => page_size.to_s,
        :appealStatus => appeal_status
    }

    response Wikimart::API_PATH + 'orders?' + Rack::Utils.escape( params.map{|k,v| "#{k}=#{v}"}.join("&") )
  end

  def orders order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}"
  end

  def orders_transitions order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}/transitions"
  end

  def orders_status order_id = nil, status = Wikimart::STATUS_CONFIRMED, reason_id = 'null', comment = ''

    params = {
        :status => status,
        :reasonId => reason_id,
        :comment => comment
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/status", params
  end

  def orders_statuses order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}/status"
  end

  def orders_comments order_id = nil, text = ''
    params = {
        :text => text
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/comments", params, Wikimart::METHOD_POST
  end

  def orders_payments_payments order_id = nil, payment_id = nil, status = Wikimart::STATUS_PAYMENT_PENDING

    params = {
        :status => status
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/payments/#{payment_id.to_s}/status", params
  end

  def orders_deliverystatus order_id = nil, state = Wikimart::STATE_CREATED, update_time = DateTime.now
    params = {
        :state => state,
        :updateTime => update_time.strftime("%Y-%m-%dT%H:%M:%S%:z")
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/deliverystatus", params
  end

  def authentication method = 'GET', content_hash = '', date = DateTime.now.rfc2822, resource = 'api/1.0/orders/'
    signature = method + "\n" + Digest::MD5.hexdigest(content_hash) + "\n"  + date.to_s + "\n" + resource
    key = @@app_secret

    digest = OpenSSL::Digest.new('sha1')
    OpenSSL::HMAC.hexdigest(digest, key, signature)
  end

  def response params
    d = DateTime.now.rfc2822.to_s

    begin
      r = open(@@host + params,
               "Accept" => "application/" + @@data_type,
               "X-WM-Date" => d,
               "X-WM-Authentication" => @@app_id + ':' + @@instance.authentication('GET', '', d, params)).read

    rescue OpenURI::HTTPError => error
      return error
    end

    case @@data_type
      when Wikimart::DATA_JSON
        JSON.parse(r)
      when Wikimart::DATA_XML
        Hash.from_xml(r)
      else
        r
    end
  end

  def request path, params, method = Wikimart::METHOD_PUT
    d = DateTime.now.rfc2822.to_s

    @uri = URI(@@host + path)

    header = {
        "Accept" => "application/" + @@data_type,
        "X-WM-Date" => d,
        "X-WM-Authentication" => @@app_id + ':' + @@instance.authentication(method, params.to_json, d, path)
    }

    if method == Wikimart::METHOD_PUT
      request = Net::HTTP::Put.new(@uri.path, header)
    else
      request = Net::HTTP::Post.new(@uri.path, header)
    end
    request.body = params.to_json
    response = Net::HTTP.new(@uri.host, @uri.port).start {|http| http.request(request) }

    if response.code != '200'
      return response.message
    end

    case @@data_type
      when Wikimart::DATA_JSON
        JSON.parse(response)
      when Wikimart::DATA_XML
        Hash.from_xml(response)
      else
        response
    end
  end

end
