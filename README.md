[![Code Climate](https://codeclimate.com/github/centosadmin/redmine_chat_telegram/badges/gpa.svg)](https://codeclimate.com/github/centosadmin/redmine_chat_telegram)
[![Build Status](https://travis-ci.org/centosadmin/redmine_chat_telegram.svg?branch=master)](https://travis-ci.org/centosadmin/redmine_chat_telegram)
# redmine_chat_telegram

[Русская версия](https://github.com/centosadmin/redmine_chat_telegram/blob/master/README.ru.md)

Plugin is developed by [Centos-admin.ru](https://centos-admin.ru)

Redmine plugin is used to create Telegram group chats.

The `redmine_chat_telegram` can be used to create a group chat associated with a ticket and record its logs to the Redmine archive. Associated group chats can be easily created via the `Create Telegram chat` link on the ticket page. You can copy the link and pass it to anyone you want to join this Telegram chat.

![Create telegram chat](https://github.com/centosadmin/redmine_chat_telegram/raw/master/assets/images/create-link.png)
![Chat links](https://github.com/centosadmin/redmine_chat_telegram/raw/master/assets/images/chat-links.png)

Please help us make this plugin better telling us of any [issues](https://github.com/centosadmin/redmine_chat_telegram/issues) you'll face using it. We are ready to answer all your questions regarding this plugin.

## Installation

### Requirements

* [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common)
* [Telegram CLI](https://github.com/vysheng/tg) should be installed
* You should have Telegram user account
* You should have Telegram bot account
* Install the [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin
* You need to configure Sidekiq queues `default` and `telegram`. [Config example](https://github.com/centosadmin/redmine_intouch/blob/master/tools/sidekiq.yml) - place it to `redmine/config` directory
* Don't forget to run migrations `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`

### Telegram CLI configuration

Take the `config/telegram.yml.example` file and use it as a template.
Copy it to `config/` folder and rename it to `telegram.yml`.
Put the correct values for the `telegram_cli_path` and `telegram_cli_public_key_path` variables.

### First time run

Start `telegram-cli` on your Redmine server and login to Telegram with it. You'll be able to create group chats after that.

### Create Telegram Bot

It is necessary to register a bot and get its token. There is a [@BotFather] bot used in Telegram for this purpose. Type `/start` to get a complete list of available commands.

Type `/newbot` command to register a new bot. @BotFather will ask you to name the new bot. The bot's name must end with the "bot" word.
On success @BotFather will give you a token for your new bot and a link so you could quickly add the bot to the contact list.
You'll have to come up with a new name if registration fails.

Set the Privacy mode to disabled with `/setprivacy`. This will let the bot listen to all group chats and write its logs to Redmine chat archive.

Enter the bot's token on the Plugin Settings page to add the bot to your chat.

To add hints for commands for the bot, use command `/setcommands`

### Add bot to user contacts

Type `/start` command to your bot from your user account.
This allows the user to add a Bot to group chats.

### Bot launch

Execute the following rake task to launch the bot:

```shell
bundle exec rake chat_telegram:bot PID_DIR='/pid/dir'
```

### Archive synchronization

Plugin can't log chat messages into the archive when stopped. To avoid loss of messages plugin performs chat - archive synchronization on the next run with 5 minute delay from the start.

## Usage

Open the ticket. You'll see the new link `Create Telegram chat` on the right side of the ticket. Click on it and the Telegram group chat associated with this ticket will be created. The link will change to `Enter Telegram chat`. Click on it to join the chat in your Telegram client. You'll be able to copy and pass the link to anyone you want to invite to the Group Chat.

### Available commands in bot chat

- `/connect` - connect Telegram account to Redmine account
- `/new` - create new issue
- `/cancel` - cancel current command

### Available commands in issue chat

- `/task`, `/link`, `/url` - get link to the issue
- `/log` - save message to the issue 

## Troubleshooting

### FAILED in the chat link

Try to change `telegram_cli_mode` in `telegram.yml` to `1`.

### Couldn't open public key file: tg-server.pub

This is CLI bug. We have [pull request](https://github.com/Rondoozle/tg/pull/4) to fix it.

Temporary solution: place `tg-server.pub` into root of Redmine.  
