[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_chat_telegram)
# redmine_chat_telegram

[English version](README.md)

[Описание плагина на habrahabr.ru](https://habrahabr.ru/company/southbridge/blog/281044/)

Плагин для Redmine для создания групповых чатов в Telegram.

Плагин `redmine_chat_telegram` используется для создания группового чата, связанного с тикетом, и записи его логов в архиве Redmine. Связанные групповые чаты могут легко быть созданы с помощью ссылки "Создать чат Telegram", которая появится на странице тикета. Вы сможете скопировать ссылку и передать её любому, кого Вы захотите подключить к этому чату.

![Create telegram chat](https://github.com/centosadmin/redmine_chat_telegram/raw/master/assets/images/create-link.png)
![Chat links](https://github.com/centosadmin/redmine_chat_telegram/raw/master/assets/images/chat-links.png)

Пожалуйста, помогите нам сделать этот плагин лучше, сообщая во вкладке [Issues](https://github.com/centosadmin/redmine_chat_telegram/issues) обо всех проблемах, с которыми Вы столкнётесь при его использовании. Мы готовы ответить на Все ваши вопросы, касающиеся этого плагина.

## Установка

### Требования

* **Ruby 2.3+**
* Настроенный [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
* У Вас должен быть аккаунт для создания ботов в Telegram
* Установите [Redis](https://redis.io) 2.8 или выше. Запустите Redis и добавьте его запуск в автозагрузку.
* Установите плагин [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq).
* Настройте Sidekiq на обработку очереди `default` и `telegram`. [Пример конфига](https://github.com/centosadmin/redmine_chat_telegram/blob/master/extras/sidekiq.yml) - разместите его в папке `redmine/config`
(Можно скопировать из plugins/redmine_chat_telegram/extras/sidekiq.yml в config/sidekiq.yml).

### Обновление с 2.1.0 до 2.2.0+

Начиная с версии 2.2.0 redmine_chat_telegram (так же, как и другие telegram-плагины от Southbridge) использует бота из redmine_telegram_common.
Чтобы произвести миграцию для использования единого бота, нужно выполнить команду `bundle exec rake telegram_common:migrate_to_single_bot`.
Token бота будет взят из одного из установленных плагинов от Southbridge в следующем приоритете:

* redmine_chat_telegram
* redmine_intouch
* redmine_2fa

Также потребуется переинициализировать бота на странице настроек redmine_telegram_common.

* Плагин устанавливается стандартно:

```
cd {REDMINE_ROOT}
git clone https://github.com/centosadmin/redmine_chat_telegram.git plugins/redmine_chat_telegram
bundle install RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```
* После необходимо запустить

### Обновление на 2.0.0

Начиная с версии 2.0.0 этот плагин использует [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
версии 0.1.0, в которой ушли от зависимости от Telegram CLI. Обратите внимание на новые зависимости.

## Использование

Убедитесь, что у вас есть работающий sidekiq, включили модуль в соответствующие проекты, а также соединили учётные записи Redmine и Telegram (см. ниже /connect).

Откройте тикет. Справа на странице Вы увидите ссылку `создать чат Telegram`. Щёлкните по ней и Вы создадите групповой чат в Telegram, который будет связан с этим тикетом. Ссылка изменится на `Войти в чат Telegram`. Щёлкните на ней чтобы присоединиться к чату, открыв его в своём клиенте Telegram. Вы сможете скопировать и передать ссылку любому кому захотите для того, чтобы он смог присоединиться к этому групповому чату.

*Замечание: новый пользователь в группе станет администратором канала, если его Telegram присоединен к Redmine (см. ниже /connect), а также имеет соответствующие права*

### Доступные команды в отдельном чате с ботом

- `/connect account@redmine.com` - связать аккаунт Telegram и Redmine
- `/new` - команда для создания новой задачи
- `/cancel` - отмена текущей команды

### Доступные команды в чате задачи

- `/task`, `/link`, `/url` - получение ссылки задачи
- `/log` - сохраняет сообщение в задачу

#### Подсказки для команд бота

Чтобы добавить подсказки команд для бота, используйте команду `/setcommands` в беседе с [@BotFather](https://telegram.me/botfather). Нужно написать боту список команд с
описанием:

```
start - начало работы с ботом.
connect - связать аккаунты Telegram и Redmine.
new - создать новую задачу.
hot - Назначенные вам задачи, обновленные за последние сутки.
me -  Назначенные вам задачи.
deadline - Назначенные вам задачи с просроченным дедлайном.
spent - Количество проставленного времени за текущие сутки.
yspent - Количество проставленного времени за вчерашние сутки.
last - Последние 5 задач с последними комментариями.
help - Помощь по командам.
chat - Управления чатами задач.
help - Справка по командам.
task - Получить ссылку на задачу.
link - Получить ссылку на задачу.
url - Получить ссылку на задачу.
log - Сохранить сообщение в задачу (укажите команду в любом месте сообщения).
issue - Редактирование задач.
```

### Автоматическое закрытие чата при закрытии задачи

После закрытия задачи, чат закроется через 2 недели автоматически.

За 1 неделю до закрытия каждые 12 часов в чат будет приходить сообщение:
"Задача по этому чату закрыта. Чат будет автоматически расформирован через XX дней."

По истечении времени все участники чата будут удалены из него.

# Автор плагина

Плагин разработан в компании [Southbridge](https://southbridge.io)
