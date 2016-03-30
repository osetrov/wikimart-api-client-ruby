require 'open-uri'

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

  STATUS_PACK_ACCEPTED           = 'accepted'
  STATUS_PACK_LEFT_TERMINAL      = 'left_terminal'
  STATUS_PACK_DISPATCHING        = 'dispatching'
  STATUS_PACK_ARRIVED_TO_CITY    = 'arrived_to_city'
  STATUS_PACK_ARRIVED_TO_OFFICE  = 'arrived_to_office'
  STATUS_PACK_DELIVERED          = 'delivered'
  STATUS_PACK_UNDELIVERED        = 'undelivered'
  STATUS_PACK_REFUND             = 'refund'

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

  # Получение статусов заказа
  def directory_order_statuses
    response Wikimart::API_PATH + 'directory/order/statuses'
  end

  # Получение списка вариантов доставки магазина
  def directory_delivery_variants
    response Wikimart::API_PATH + 'directory/delivery/variants/'
  end

  # Получение списка регионов/городов доставки
  def directory_delivery_location delivery_id = nil
    response Wikimart::API_PATH + "directory/delivery/#{delivery_id}/location"
  end

  # Получение списка статусов доставки
  def directory_delivery_statuses
    response Wikimart::API_PATH + 'directory/delivery/statuses'
  end

  # Получение списка способов оплат
  def directory_payment_types
    response Wikimart::API_PATH + 'directory/payment/types'
  end

  # Получение списка причин апелляций
  def directory_appeal_subject
    response Wikimart::API_PATH + 'directory/appeal/subject'
  end

  # Получение списка статусов апелляций
  def directory_status
    response Wikimart::API_PATH + 'directory/appeal/status'
  end

  # Получение статусов заказа
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

  # Получение информации о заказе
  def orders order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}"
  end

  ## Смена статуса заказа
  # Получение списка причин для смены статуса
  def orders_transitions order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}/transitions"
  end

  # Запрос на смену статуса заказа
  def orders_status order_id = nil, status = Wikimart::STATUS_CONFIRMED, reason_id = 'null', comment = ''

    params = {
        :status => status,
        :reasonId => reason_id,
        :comment => comment
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/status", params
  end

  # Получение истории смены статусов заказа
  def orders_statuses order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}/status"
  end

  ## Добавление комментария к заказу
  # Запрос на добавление комментария
  def orders_comments order_id = nil, text = ''
    params = {
        :text => text
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/comments", params, Wikimart::METHOD_POST
  end

  # Получение комментариев заказа
  def orders_payments_payments order_id = nil, payment_id = nil, status = Wikimart::STATUS_PAYMENT_PENDING

    params = {
        :status => status
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/payments/#{payment_id.to_s}/status", params
  end

  # Изменение статуса доставки
  def orders_deliverystatus order_id = nil, state = Wikimart::STATE_CREATED, update_time = DateTime.now
    params = {
        :state => state,
        :updateTime => update_time.strftime("%Y-%m-%dT%H:%M:%S%:z")
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/deliverystatus", params
  end

  # Получение списка возможных причин претензий
  def orders_appealsubjects order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}/appealsubjects/"
  end

  # Создание претензии по заказу
  def orders_appeals order_id = nil, subject_id = nil, comment = ''
    params = {
        :subjectID => subject_id,
        :comment   => comment
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/appeals", params, Wikimart::METHOD_POST
  end

  # Регистрация нового отправления
  def new_orders_packages order_id = nil, service = '', package_id = nil, items = []
    params = {
        :service => service,
        :packageId   => package_id,
        :items => items
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/packages", params, Wikimart::METHOD_POST
  end

  # Получение списка отправлений по заказу
  def get_orders_packages order_id = nil
    response Wikimart::API_PATH + "orders/#{order_id.to_s}/packages/"
  end

  # Обновить статус посылки
  def set_orders_packages_states order_id = nil, package_id = nil, state = Wikimart::STATUS_PACK_ACCEPTED,
                                 update_time = DateTime.now
    params = {
        :state => state,
        :updateTime => update_time.strftime("%Y-%m-%dT%H:%M:%S%:z")
    }

    request Wikimart::API_PATH + "orders/#{order_id.to_s}/packages/#{package_id.to_s}/states", params
  end

  # Обновление товаров
  def set_offers offers = []
    request Wikimart::API_PATH + "orders/offers", offers
  end

  # Получение информации о статусе и цене товаров
  def get_offets yml_id = nil, own_id = [], city = nil
    params = {
        :own_id   => own_id,
        :city => city
    }

    request Wikimart::API_PATH + "orders/offers/#{yml_id.to_s}", params, Wikimart::METHOD_POST
  end

  # Создание и обновление контентной информации о товарах
  def set_content_offers yml_id = nil, own_id = nil, category_id = nil, name = nil, description = '', wikimart_model_id = nil,
                         vendor_code = nil, vendor = nil, params = [], image_urls = []

    params = {
        :category_id => category_id,
        :name => name,
        :description => description,
        :wikimart_model_id => wikimart_model_id,
        :vendor_code => vendor_code,
        :vendor => vendor,
        :params => params,
        :image_urls => image_urls
    }

    request Wikimart::API_PATH + "content/#{yml_id.to_s}/offers/#{own_id.to_s}", params
  end

  # Получение контентной информации о товаре
  def get_content_offers yml_id = nil, own_id = nil
    response Wikimart::API_PATH + "content/#{yml_id.to_s}/offers/#{own_id.to_s}"
  end

  # Создание и обновление категории
  def set_content_categories yml_id = nil, id = nil, parent_id = nil, name = ''

    params = {
        :parent_id => parent_id,
        :name => name
    }

    request Wikimart::API_PATH + "content/#{yml_id.to_s}/categories/#{id.to_s}", params
  end

  # Удаление категории
  def del_content_categories yml_id = nil, id = nil
    params = {}
    request Wikimart::API_PATH + "content/#{yml_id.to_s}/categories/#{id.to_s}", params, Wikimart::METHOD_DELETE
  end

  # Получение информации о категории
  def get_content_categories yml_id = nil, id = nil
    response Wikimart::API_PATH + "content/#{yml_id.to_s}/categories/#{id.to_s}"
  end

  # Создание бандла с идентификатором ID
  def new_bundles id = nil, name = '', description = '', start_time = DateTime.now, end_time = (DateTime.now + 1.days),
                  is_available = 1, slots = [], bonus = []
    params = {
        :name => name,
        :description => description,
        :startTime => start_time,
        :endTime  => end_time,
        :isAvailable => is_available,
        :slots  => slots,
        :bonus  => bonus
    }
    request Wikimart::API_PATH + "bundles/#{id.to_s}", params, Wikimart::METHOD_POST
  end

  # Изменение бандла с идентификатором ID
  def set_bundles id = nil, name = '', description = '', start_time = DateTime.now, end_time = (DateTime.now + 1.days),
                  is_available = 1, slots = [], bonus = []
    params = {
        :name => name,
        :description => description,
        :startTime => start_time,
        :endTime  => end_time,
        :isAvailable => is_available,
        :slots  => slots,
        :bonus  => bonus
    }
    request Wikimart::API_PATH + "bundles/#{id.to_s}", params
  end

  # Удаление бандла
  def del_bundles id = nil
    params = {}
    request Wikimart::API_PATH + "bundles/#{id.to_s}", params, Wikimart::METHOD_DELETE
  end

  private

  # Аутентификация
  def authentication method = 'GET', content_hash = '', date = DateTime.now.rfc2822, resource = 'api/1.0/orders/'
    signature = method + "\n" + Digest::MD5.hexdigest(content_hash) + "\n"  + date.to_s + "\n" + resource
    key = @@app_secret

    digest = OpenSSL::Digest.new('sha1')
    OpenSSL::HMAC.hexdigest(digest, key, signature)
  end

  # Ответ на GET
  def response params
    d = DateTime.now.rfc2822.to_s

    begin
      r = open(@@host + params,
               "Accept" => "application/" + @@data_type,
               "X-WM-Date" => d,
               "X-WM-Authentication" => @@app_id + ':' + authentication('GET', '', d, params)).read

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

  # Ответ на PUT/POST/DELETE
  def request path, params, method = Wikimart::METHOD_PUT
    d = DateTime.now.rfc2822.to_s

    @uri = URI(@@host + path)

    header = {
        "Accept" => "application/" + @@data_type,
        "X-WM-Date" => d,
        "X-WM-Authentication" => @@app_id + ':' + authentication(method, params.to_json, d, path)
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
