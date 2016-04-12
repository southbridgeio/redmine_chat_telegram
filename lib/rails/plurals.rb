# encoding: utf-8
require 'redmine/i18n'
require 'i18n/backend/pluralization'

Redmine::I18n::Backend.send :include, I18n::Backend::Pluralization

TELEGRAM_CHAT_PLURALIZATIONS = {
  :en => { :i18n => { :plural => { :keys => [:one, :other], :rule => lambda { |n| n == 1 ? :one : :other } } } },
  :ru => { :i18n => { :plural => { :keys => [:one, :few, :many, :other], :rule => lambda { |n| n % 10 == 1 && n % 100 != 11 ? :one : [2, 3, 4].include?(n % 10) && ![12, 13, 14].include?(n % 100) ? :few : n % 10 == 0 || [5, 6, 7, 8, 9].include?(n % 10) || [11, 12, 13, 14].include?(n % 100) ? :many : :other } } } },
}

module I18nPluralizationLoader
  def init_translations(locale)
    super.tap do
      if TELEGRAM_CHAT_PLURALIZATIONS.key?(locale)
        store_translations locale, TELEGRAM_CHAT_PLURALIZATIONS[locale]
      else
        lang = locale.to_s.split('-', 2).first.to_sym
        if TELEGRAM_CHAT_PLURALIZATIONS.key?(lang)
          store_translations locale, TELEGRAM_CHAT_PLURALIZATIONS[lang]
        end
      end
    end
  end
end

Redmine::I18n::Backend.send :include, I18nPluralizationLoader
