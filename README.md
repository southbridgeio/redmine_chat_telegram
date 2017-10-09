[![Code Climate](https://codeclimate.com/github/centosadmin/redmine_chat_telegram/badges/gpa.svg)](https://codeclimate.com/github/centosadmin/redmine_chat_telegram)
[![Build Status](https://travis-ci.org/centosadmin/redmine_chat_telegram.svg?branch=master)](https://travis-ci.org/centosadmin/redmine_chat_telegram)
[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_chat_telegram)
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
### Upgrade to 2.0.0

Since version 2.0.0 this plugin uses [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
0.1.0 version, where removed Telegram CLI dependency. Please, take a look on new requirements.

### Create Telegram Bot

It is necessary to register a bot and get its token.
There is a [@BotFather](https://telegram.me/botfather) bot used in Telegram for this purpose.
Type `/start` to get a complete list of available commands.

Type `/newbot` command to register a new bot.
[@BotFather](https://telegram.me/botfather) will ask you to name the new bot. The bot's name must end with the "bot" word.
On success @BotFather will give you a token for your new bot and a link so you could quickly add the bot to the contact list.
You'll have to come up with a new name if registration fails.

Set the Privacy mode to disabled with `/setprivacy`. This will let the bot listen to all group chats and write its logs to Redmine chat archive.

Enter the bot's token on the Plugin Settings page to add the bot to your chat.

To add hints for commands for the bot, use command `/setcommands`. You need to send list of commands with descriptions. You can get this list from command `/help`.

### Bot modes

Bot can work in two [modes](https://core.telegram.org/bots/api#getting-updates) — getUpdates or WebHooks.

#### getUpdates

To work via getUpdates, you should run bot process `bundle exec rake chat_telegram:bot`.
This will drop bot WebHook setting.

#### WebHooks

To work via WebHooks, you should go to plugin settings and press button "Initialize bot"
(bot token should be saved earlier, and notice redmine should work on https)


### Add bot to user contacts

Type `/start` command to your bot from your user account.
This allows the user to add a Bot to group chats.

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
