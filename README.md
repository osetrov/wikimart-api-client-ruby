Wikimart Merchant API client (Ruby)
===================

Описание Wikimart Merchant API: http://merchant.wikimart.ru/api/1.0/doc

Например получение списка причин апелляций
APP_ID = '13473618150931'
APP_SECRET = 'Mh5EDL9TPnm3A1JAIoHM0w'

p Wikimart.instance(APP_ID, APP_SECRET).directory_appeal_subject

Получение списка статусов апелляций
DATA_TYPE = 'json' #xml
HOST = 'http://merchant.wikimart.ru'

p Wikimart.instance(APP_ID, APP_SECRET, DATA_TYPE, DATA_TYPE, HOST).directory_status