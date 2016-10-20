#### [1.2.0]

* Add ability to connect telegram accounts to redmine

#### [1.1.3]

* Solve issue #6 by add `telegram_cli_mode` to `telegram.yml`

#### [1.1.2]
* Add `history_update` rake task for sync old archive messages. Need if bot was turned off long time ago.
* Add needed gems to `Gemfile`
* Bug fixes

#### [1.1.1]
 * Fix styles in arhive modal window
 * Fix sending issue notification to telegram chat
 * Add formating for issue notification messages

#### 1.1.0
 * [3dce957](../../commit/3dce957) - __(Artur Trofimov)__ Replace Telegram CLI command exec with run Telegram CLI as daemon

#### 1.0.6
 * [58a8c13](../../commit/58a8c13) - __(Artur Trofimov)__ version update, add changelog
 * [ea64ed0](../../commit/ea64ed0) - __(Artur Trofimov)__ Refactoring for CLI command, fix bug with wrong shared link, get CLI output as JSON

#### 1.0.5


#### 122080
 * [6c3b491](../../commit/6c3b491) - __(Artur Trofimov)__ version update
 * [6be6711](../../commit/6be6711) - __(Artur Trofimov)__ Remove archive messages and close chat on issue destroy
 * [56b715b](../../commit/56b715b) - __(Artur Trofimov)__ Remove unneeded attributes from issues
 * [b3f6990](../../commit/b3f6990) - __(Artur Trofimov)__ Exclude messages from bot or robot
 * [45661ba](../../commit/45661ba) - __(Artur Trofimov)__ Fix for messages without journal details
 * [62d39d8](../../commit/62d39d8) - __(Artur Trofimov)__ Publish report only if messages present
 * [fb90198](../../commit/fb90198) - __(Stepan Lusnikov)__ Push issues changes to telegram group
 * [617fe99](../../commit/617fe99) - __(Stepan Lusnikov)__ Redirect after create and destroy chat
 * [7aed8e9](../../commit/7aed8e9) - __(Artur Trofimov)__ Fix for anonymous user, select uniq issues for daily report

* develop:
  Do not select message by click

 * [74c5e46](../../commit/74c5e46) - __(Stepan Lusnikov)__ Do not select message by click

Go to message from search by click

 * [642cb80](../../commit/642cb80) - __(Artur Trofimov)__ Add logging for CLI, extract CLI request to module, typo fix

#### 120909
 * [5d82e74](../../commit/5d82e74) - __(Artur Trofimov)__ Fix for daily report logic, extract issue report in separate worker
 * [528b220](../../commit/528b220) - __(Igor Olemskoi)__ Update init.rb

#### 1.0.4
 * [72ee652](../../commit/72ee652) - __(Artur Trofimov)__ Fix in chat destroy process

* hotfix/chat-destroy:
  Redirect to issue page after destroy chat


* hotfix/ajax-history-load:
  Fix autoload issue history after create chat


* release/1.0.1:
  Release 1.0.1

#### 121682
 * [0e4deef](../../commit/0e4deef) - __(Artur Trofimov)__ bot hotfix

* hotfix/chat-destroy:
  Redirect to issue page after destroy chat

 * [ed7a503](../../commit/ed7a503) - __(Stepan Lusnikov)__ Redirect to issue page after destroy chat

* hotfix/ajax-history-load:
  Fix autoload issue history after create chat

 * [ee33920](../../commit/ee33920) - __(Stepan Lusnikov)__ Fix autoload issue history after create chat

* release/1.0.1:
  Release 1.0.1
  Delete go to message link in search

 * [3bb0b92](../../commit/3bb0b92) - __(Stepan Lusnikov)__ Release 1.0.1
 * [ff09a68](../../commit/ff09a68) - __(Stepan Lusnikov)__ Delete go to message link in search

Now need to click on the message to go
to it from search.


#### 1.0.0
 * [0acbe09](../../commit/0acbe09) - __(Artur Trofimov)__ Release 1.0.0
 * [d6c7dfc](../../commit/d6c7dfc) - __(Artur Trofimov)__ Typo fixes, little refactoring
 * [49f887b](../../commit/49f887b) - __(Stepan Lusnikov)__ Localize TelegramGroupDailyReportWorker
 * [ea131c4](../../commit/ea131c4) - __(Stepan Lusnikov)__ Date format in archive from redmine settings
 * [d2c2c10](../../commit/d2c2c10) - __(Stepan Lusnikov)__ Localize system messages
 * [da98122](../../commit/da98122) - __(Stepan Lusnikov)__ Add system_data to TelegramMessage
 * [2a42b9f](../../commit/2a42b9f) - __(Stepan Lusnikov)__ Localize views

#### 1.0.0.beta3
 * [1811ec6](../../commit/1811ec6) - __(Artur Trofimov)__ Write sidekiq log to sidekiq.log
 * [f6755dd](../../commit/f6755dd) - __(Artur Trofimov)__ Disallow create telegram chat from closed issue

#### 119754
 * [0e60965](../../commit/0e60965) - __(Artur Trofimov)__ Move cli_base to lib, fix chat destroy, add bot_name to settings as hidden field, fix save bot name

#### 1.0.0.beta
 * [ba4de24](../../commit/ba4de24) - __(Artur Trofimov)__ version update
 * [1932ce5](../../commit/1932ce5) - __(Stepan Lusnikov)__ Add goto message link in search

* hotfix/ajax-comments-loading:
  Chage selector for finding issue


* hotfix/ajax-comments-loading:
  Chage selector for finding issue

 * [32c776a](../../commit/32c776a) - __(Stepan Lusnikov)__ Chage selector for finding issue
 * [ee08887](../../commit/ee08887) - __(Artur Trofimov)__ Save bot id on init, fix issue search
 * [2751569](../../commit/2751569) - __(Artur Trofimov)__ Add daily report to CRON
 * [29654d2](../../commit/29654d2) - __(Artur Trofimov)__ Add bot message attribute to TelegramMessage, Add daily report worker, add some localization, bot can identify bot messages
 * [63f7f59](../../commit/63f7f59) - __(Artur Trofimov)__ Add daily report to plugin settings
 * [dcb8c7b](../../commit/dcb8c7b) - __(Artur Trofimov)__ Fix chat destroy, add comment after destroy, remove ajax on destroy

* hotfix/autor_initials:
  Fir author initials


* hotfix/autor_initials:
  Fir author initials

 * [e7dd8f3](../../commit/e7dd8f3) - __(Stepan Lusnikov)__ Fir author initials

#### 0.10.1
 * [8c0bc67](../../commit/8c0bc67) - __(Artur Trofimov)__ Cleanup after release auto-close feature

#### 0.10.0
 * [6259fb5](../../commit/6259fb5) - __(Artur Trofimov)__ Version update
 * [9f50be8](../../commit/9f50be8) - __(Artur Trofimov)__ Finish with auto close feature
 * [c116a01](../../commit/c116a01) - __(Artur Trofimov)__ Add workers
 * [715f82a](../../commit/715f82a) - __(Artur Trofimov)__ send notification to chat before close it
 * [ffba883](../../commit/ffba883) - __(Artur Trofimov)__ Add TelegramGroup model, update old logic for use it.

* release/0.9.1:
  Update version

#### cleanup
 * [a745bdb](../../commit/a745bdb) - __(Artur Trofimov)__ Add issues helper to TelegramGroupChatsController
 * [c2b7514](../../commit/c2b7514) - __(Stepan Lusnikov)__ Fix user initials

* release/0.9.1:
  Update version
  Highlight search results
  Add search in archive

 * [0a2d917](../../commit/0a2d917) - __(Stepan Lusnikov)__ Update version

* feature/search:
  Highlight search results
  Add search in archive

 * [a695f19](../../commit/a695f19) - __(Stepan Lusnikov)__ Highlight search results
 * [74e9f22](../../commit/74e9f22) - __(Stepan Lusnikov)__ Add search in archive

* release/0.9.0:
  Update version


* release/0.9.0:
  Update version
  Add ability to select messages by click
  Different colors for users in chat
  Change date style
  Different style for system and normal messages
  Mark system telegram messages in rake task
  Add is_system to telegram messages
  Add photos with author initials
  Redesign telegram messages

 * [5cbc233](../../commit/5cbc233) - __(Stepan Lusnikov)__ Update version

* feature/redesign:
  Add ability to select messages by click
  Different colors for users in chat
  Change date style
  Different style for system and normal messages
  Mark system telegram messages in rake task
  Add is_system to telegram messages
  Add photos with author initials
  Redesign telegram messages

 * [bf2954f](../../commit/bf2954f) - __(Stepan Lusnikov)__ Add ability to select messages by click
 * [1132e1d](../../commit/1132e1d) - __(Stepan Lusnikov)__ Different colors for users in chat
 * [4303c67](../../commit/4303c67) - __(Stepan Lusnikov)__ Change date style
 * [2556bdb](../../commit/2556bdb) - __(Stepan Lusnikov)__ Different style for system and normal messages
 * [b4d1b37](../../commit/b4d1b37) - __(Stepan Lusnikov)__ Mark system telegram messages in rake task
 * [31420fd](../../commit/31420fd) - __(Stepan Lusnikov)__ Add is_system to telegram messages
 * [840c44f](../../commit/840c44f) - __(Stepan Lusnikov)__ Add photos with author initials
 * [1a18af9](../../commit/1a18af9) - __(Stepan Lusnikov)__ Redesign telegram messages

* release/0.8.3:
  Update version


* release/0.8.3:
  Update version
  Load issue history after creating a chat

 * [f0b9043](../../commit/f0b9043) - __(Stepan Lusnikov)__ Update version
 * [b7eae99](../../commit/b7eae99) - __(Stepan Lusnikov)__ Load issue history after creating a chat
 * [b92919d](../../commit/b92919d) - __(Stepan Lusnikov)__ Merge pull request [#3](../../issues/3) from centosadmin/doc

Create README.ru.md
 * [a944cd1](../../commit/a944cd1) - __(openforceru)__ Create README.ru.md
 * [3f308e2](../../commit/3f308e2) - __(Stepan Lusnikov)__ Fix telegram links styles
 * [fc713e8](../../commit/fc713e8) - __(Stepan Lusnikov)__ Merge pull request [#2](../../issues/2) from centosadmin/doc

Update README.md
 * [8723cff](../../commit/8723cff) - __(openforceru)__ Update README.md
 * [363f6c9](../../commit/363f6c9) - __(Artur Trofimov)__ Merge pull request [#1](../../issues/1) from openforceru/patch-1

Update README.md
 * [1ee8b39](../../commit/1ee8b39) - __(openforceru)__ Update README.md
 * [90e52fb](../../commit/90e52fb) - __(Artur Trofimov)__ Hide preview on link post (cherry picked from commit 81ff761)

* release/0.8.2:
  Update version
  Chnage style for arhive date

 * [c226d4d](../../commit/c226d4d) - __(Stepan Lusnikov)__ Update version
 * [3201e0a](../../commit/3201e0a) - __(Stepan Lusnikov)__ Chnage style for arhive date

* release/0.8.1:
  Update version


* release/0.8.1:
  Update version
  Change css for archive
  Change archive modal window

 * [b55be12](../../commit/b55be12) - __(Stepan Lusnikov)__ Update version
 * [3ba4c0c](../../commit/3ba4c0c) - __(Stepan Lusnikov)__ Change css for archive
 * [7d0f750](../../commit/7d0f750) - __(Stepan Lusnikov)__ Change archive modal window

- Change button text
- Add seporators for dates
- Disable focus on input after open modal

 * [325dfa8](../../commit/325dfa8) - __(Artur Trofimov)__ Merge remote-tracking branch 'origin/master'

# Conflicts:
#	init.rb

 * [75d7a5f](../../commit/75d7a5f) - __(Stepan Lusnikov)__ Update version
 * [45a68e2](../../commit/45a68e2) - __(Stepan Lusnikov)__ Group messages by date

Change date format

#### 0.8.0
 * [5079489](../../commit/5079489) - __(Artur Trofimov)__ Add close chat feature

* release/0.7.1:
  Update version

 * [1d06e8c](../../commit/1d06e8c) - __(Stepan Lusnikov)__ Update version
 * [803694c](../../commit/803694c) - __(Stepan Lusnikov)__ Group messages by date

Change date format


#### 0.7.0
 * [283ff62](../../commit/283ff62) - __(Artur Trofimov)__ 0.7.0
 * [50da300](../../commit/50da300) - __(Artur Trofimov)__ Add create chat, user join and exit messages to archive
 * [aafa51c](../../commit/aafa51c) - __(Artur Trofimov)__ Add aliases for `/task`: `/link`, `/url` Remove time from journal log Little text and style fixes
 * [e1f8807](../../commit/e1f8807) - __(Artur Trofimov)__ Update roles permissions. Add permission for view chat link and archive. Remove project settings

#### 0.6.3
 * [17e5352](../../commit/17e5352) - __(Artur Trofimov)__ update version

* task_118738:
  Add date picker to arhive and change styles
  Show archive in modal window
  Add icon for archive and inactive telegram
  Do not show form in empty archive
  Open chat archive in popup

 * [ef3097b](../../commit/ef3097b) - __(Stepan Lusnikov)__ Add date picker to arhive and change styles
 * [eb87dfd](../../commit/eb87dfd) - __(Stepan Lusnikov)__ Show archive in modal window
 * [fc6c34e](../../commit/fc6c34e) - __(Stepan Lusnikov)__ Add icon for archive and inactive telegram
 * [47fe0b9](../../commit/47fe0b9) - __(Stepan Lusnikov)__ Do not show form in empty archive
 * [215583c](../../commit/215583c) - __(Stepan Lusnikov)__ Open chat archive in popup

#### rollback-roles
 * [6717904](../../commit/6717904) - __(Artur Trofimov)__ Hotfix: rollback roles permission for enabled module Project settings: admin can select who can create Telegram group Add journal entry with link to chat after it created

#### small-tuning
 * [e029932](../../commit/e029932) - __(Artur Trofimov)__ Hotfix: fix permission for enabled module

#### alarm
 * [13d4f4c](../../commit/13d4f4c) - __(Artur Trofimov)__ hotfix

#### 0.6.0
 * [8aa4998](../../commit/8aa4998) - __(Artur Trofimov)__ Add project settings: select groups who can create telegram group Reorganize lib folders

#### 0.5.0
 * [bd9c533](../../commit/bd9c533) - __(Artur Trofimov)__ Add telegram id to issue

#### 0.4.0
 * [afda962](../../commit/afda962) - __(Artur Trofimov)__ Add logging by `!log` keyword

#### 0.3.0
 * [a49eb39](../../commit/a49eb39) - __(Artur Trofimov)__ Bot send issue link after create chat and after `/link` command

#### 0.2.0
 * [48f4465](../../commit/48f4465) - __(Artur Trofimov)__ Add permission for create telegram chat
 * [7c4cfde](../../commit/7c4cfde) - __(Artur Trofimov)__ Add feature for view issue telegram messages and publish selected of its
 * [e063d65](../../commit/e063d65) - __(Artur Trofimov)__ Use plugin as project module
 * [6130bf1](../../commit/6130bf1) - __(Artur Trofimov)__ Replace create button with link, add ajax on create chat
 * [161b158](../../commit/161b158) - __(Artur Trofimov)__ fix telegram link in issue
 * [a6022d8](../../commit/a6022d8) - __(Igor Olemskoi)__ Update chat_telegram.rake
 * [c25258b](../../commit/c25258b) - __(Igor Olemskoi)__ Update Gemfile
 * [119a378](../../commit/119a378) - __(Artur Trofimov)__ Add bot launch instruction to readme
 * [52a6f1f](../../commit/52a6f1f) - __(Artur Trofimov)__ Add message login, add bot rake task, add icon to link
 * [86284a6](../../commit/86284a6) - __(Artur Trofimov)__ Regexp fix, update README
 * [2a6916d](../../commit/2a6916d) - __(Artur Trofimov)__ Get CLI paths for config
 * [cb6f54b](../../commit/cb6f54b) - __(Igor Olemskoi)__ Update telegram_group_chats_controller.rb
 * [dc51859](../../commit/dc51859) - __(Igor Olemskoi)__ Update redmine_chat_telegram.rb
 * [013b36c](../../commit/013b36c) - __(Artur Trofimov)__ First release
 * [8f8e580](../../commit/8f8e580) - __(Artur Trofimov)__ Update README
 * [0af4c48](../../commit/0af4c48) - __(Artur Trofimov)__ init
