# THIS PLUGIN IS DEPRECATED! PLEASE, USE [REDMINE_2CHAT](https://github.com/centosadmin/redmine_2chat) INSTEAD

# redmine_chat_telegram

[Русская версия](README.ru.md)

Redmine plugin is used to create Telegram group chats.

The `redmine_chat_telegram` can be used to create a group chat associated with a ticket and record its logs to the Redmine archive. Associated group chats can be easily created via the `Create Telegram chat` link on the ticket page. You can copy the link and pass it to anyone you want to join this Telegram chat.

![Create telegram chat](https://github.com/centosadmin/redmine_chat_telegram/raw/master/assets/images/create-link.png)
![Chat links](https://github.com/centosadmin/redmine_chat_telegram/raw/master/assets/images/chat-links.png)

Please help us make this plugin better telling us of any [issues](https://github.com/centosadmin/redmine_chat_telegram/issues) you'll face using it. We are ready to answer all your questions regarding this plugin.

## Installation

### Requirements

* **Ruby 2.3+**
* Configured [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
version 1.4.1 has problems with archive sync.
* You should have Telegram bot account
* Install [Redis](https://redis.io) 2.8 or higher. Run Redis and add it to autorun.
* Install the [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin
* You need to configure Sidekiq queues `default` and `telegram`. [Config example](https://github.com/centosadmin/redmine_chat_telegram/blob/master/extras/sidekiq.yml) - place it to `redmine/config` directory (Or copy from plugins/redmine_chat_telegram/extras/sidekiq.yml to config/sidekiq.yml).

* Standard install plugin:

```
cd {REDMINE_ROOT}
git clone https://github.com/centosadmin/redmine_chat_telegram.git plugins/redmine_chat_telegram
bundle install RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

*Note: each of our plugins requires separate bot. It won't work if you use the same bot for several plugins.*

### Upgrade from 2.1.0 to 2.2.0+

From 2.2.0 redmine_chat_telegram (as well as other Southbridge telegram plugins) is using bot from redmine_telegram_common.
In order to perform migration to single bot you should run `bundle exec rake telegram_common:migrate_to_single_bot`.
Bot token will be taken from one of installed Southbridge plugins in the following priority:

* redmine_chat_telegram
* redmine_intouch
* redmine_2fa

Also you should re-initialize bot on redmine_telegram_common settings page.

### Upgrade to 2.0.0

Since version 2.0.0 this plugin uses [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
0.1.0 version, where removed Telegram CLI dependency. Please, take a look on new requirements.

## Usage

Make sure you have running sidekiq, turn on module in project, also connected Redmine and Telegram accounts (see /connect below).

Open the ticket. You'll see the new link `Create Telegram chat` on the right side of the ticket. Click on it and the Telegram group chat associated with this ticket will be created. The link will change to `Enter Telegram chat`. Click on it to join the chat in your Telegram client. You'll be able to copy and pass the link to anyone you want to invite to the Group Chat.

*Note: a new user in group will became group administrator, if his Telegram account connected to Redmine (see /connect below) and have proper permissions*

### Available commands in dedicated bot chat

- `/connect account@redmine.com` - connect Telegram account to Redmine account
- `/new` - create new issue
- `/cancel` - cancel current command

### Available commands in issue chat

- `/task`, `/link`, `/url` - get link to the issue
- `/log` - save message to the issue

#### Hints for bot commands

Use command `/setcommands` with [@BotFather](https://telegram.me/botfather). Send this list for setup hints:

```
start - Start work with bot.
connect - Connect account to Redmine.
new - Create new issue.
hot - Assigned to you issues updated today.
me - Assigned to you issues.
deadline - Assigned to you issues with expired deadline.
spent - Number of hours set today.
yspent - Number of hours set yesterday.
last - Last 5 issues with comments.
help - Help.
chat - Manage issues chats.
task - Get link to the issue.
link - Get link to the issue.
url - Get link to the issue.
log - Save message to the issue.
issue - Change issues.
```

# Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
