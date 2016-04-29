# redmine_chat_telegram

[Русская версия](https://github.com/centosadmin/redmine_chat_telegram/blob/master/README.ru.md)

Plugin developed by [Centos-admin.ru](https://centos-admin.ru)

Redmine plugin used to create Telegram group chats.

The `redmine_chat_telegram` can be used to create a group chat associated with a ticket and record its logs to the Redmine archive. Associated group chats can be easily created via the `Create Telegram chat` link on the ticket page. You're able to copy the link and pass it to anyone you'll want to join this Telegram chat.

Please help us make this plugin better telling us of any [issues](https://github.com/centosadmin/redmine_chat_telegram/issues) you'll face using it. We are ready to answer all your questions regarding this plugin.

## Installation

### Requirements

* [Telegram CLI](https://github.com/vysheng/tg) should be installed
* You should have Telegram user account
* You should have Telegram bot account
* Install [Telegrammer gem](https://github.com/mayoral/telegrammer), place it in your `Gemfile.local`)
* Install the [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin

### Telegram CLI configuration

Take the `config/telegram.yml.example` file and use it as a template.
Copy it to `config/` folder and rename it to `telegram.yml`.
Put the correct values for the `telegram_cli_path` and `telegram_cli_public_key_path` variables.

### First time run

Start `telegram-cli` on your Redmine server and login to Telegram with it. You'll be able to create group chats after that.

### Create Telegram Bot

It is necessary to register a bot and get its token. There is a [@BotFather] bot used in Telegram for this purpose. Type `/start` to get a complete list of available commands.

Type `/newbot` command to register a new bot. @BotFather will ask you a name for the new bot. The bot's name must end with the "bot" word.
On success @BotFather will give you token for your new bot and a link so you could quickly add the bot to contact list.
You'll have to come up with a new name if registration fails.

Set the Privacy mode to disabled with `/setprivacy`. This will let the bot listen all group chats and write its logs to Redmine chat archive.

Enter bot's token on the Plugin Settings page to add the bot to your chat.

### Add bot to user contacts

Type `/start` command to your bot from your user account.
This allows user to add Bot to group chats.

### Bot launch

Execute the following rake task to launch the bot:

```shell
bundle exec rake chat_telegram:bot PID_DIR='/pid/dir'
```

### Archive synchronization

Plugin can't log chat messages into archive when stopped. To avoid loss of messages plugin performs chat - archive synchronization on the next run with 5 minute delay from start.

### Usage

Open the ticket. You'll see the new link `Create Telegram chat` on the right side of the ticket. Click it and the Telegram group chat associated with this ticket will be created. The link will change to `Enter Telegram chat`. Click on in to join the chat in your Telegram client. You'll be able to copy and pass the link to anyone you want to invite them to the Group Chat.
