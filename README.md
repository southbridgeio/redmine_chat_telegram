# redmine_chat_telegram

Redmine plugin which creates telegram group chats

## Installation

### Requirements

* You need to install the [Telegram CLI](https://github.com/vysheng/tg) first
* Telegram user account
* Telegram bot account
* [Telegrammer gem](https://github.com/mayoral/telegrammer) (place it in your `Gemfile.local`)
* [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin

### Config for Telegram CLI

Use `config/telegram.yml.example` as example.

Copy it to `config/telegram.yml` it plugin root and set your values for CLI and public key paths.

### Authorize telegram user

You need to run `telegram-cli` manually on your Redmine server.

On first run you will authorize your user account.

Plugin will can create group chats _after_ that.

### Create Telegram Bot

It is necessary to register a bot and get its token. There is a special bot in Telegram for this purpose. It is called [@BotFather](https://telegram.me/botfather).

Start it by typing `/start` to get a list of all available commands.
Issue the  `/newbot` command and it will ask you to come up with the name for our new bot.
The name must end with "bot" word.
On success @BotFather will give you token for your new bot and a link so you could quickly add the bot to contact list.
You'll have to invent a new name if the registration fails.

Also set Privacy mode to disabled by command `/setprivacy`. This allows bot to listen all group chat messages for writing its to Redmine chat archive.

You should enter bot's token and name (not @username) on the Plugin Settings page.

### Add bot to user contacts

Send `/start` command to your bot from user account.
This allows user to add Bot to group chats.

### Bot launch

Bot rake task:

```shell
bundle exec rake chat_telegram:bot PID_DIR='/pid/dir'
```
