# frozen_string_literal: true

require 'rails_helper'
require 'json'

RSpec.describe I18nFeedback::Widget do
  def config_from(snippet)
    JSON.parse(snippet[%r{data-i18n-feedback-config>(.*?)</script>}m, 1])
  end

  it 'stays out of the host asset pipeline (no app/assets to auto-register)' do
    expect(I18nFeedback::Engine.paths['app/assets'].existent).to be_empty
    expect(File.exist?(I18nFeedback::Widget::SOURCE)).to be(true)
  end

  describe '.snippet labels' do
    # These locales aren't in the dummy app's available_locales; the enforcement
    # is about the app's own locale, not which translations the gem ships.
    #
    # A prior request example runs the Rails reloader, which filters the loaded
    # backend down to the app's available_locales ([:en, :fr]) — so reload the
    # full load_path (all shipped gem locales) to keep this example order-proof.
    around do |example|
      original = I18n.enforce_available_locales
      I18n.enforce_available_locales = false
      I18n.reload!
      I18n.backend.load_translations
      example.run
    ensure
      I18n.enforce_available_locales = original
    end

    it 'ships translations for the bundled locales' do
      # A spot check across scripts: Latin, Cyrillic, CJK, Arabic, Devanagari.
      samples = {
        'de' => 'Vorschlag senden',
        'ru' => 'Отправить предложение',
        'ja' => '提案を送信',
        'ar' => 'إرسال الاقتراح',
        'hi' => 'सुझाव भेजें'
      }

      samples.each do |locale, expected|
        value = I18n.t(:save, scope: :i18n_feedback, locale: locale)
        expect(value).to eq(expected),
                         "#{locale}.i18n_feedback.save: expected #{expected.inspect}, got #{value.inspect}"
      end
    end

    it 'falls back to English for a locale with no shipped translation' do
      expect(I18n.t(:save, scope: :i18n_feedback, locale: :xx, default: 'Send suggestion')).to eq('Send suggestion')
    end

    it 'resolves labels under the requested locale, not the ambient I18n.locale' do
      config = I18n.with_locale(:en) do
        config_from(described_class.snippet(endpoint: '/x', locale: :fr, active: false))
      end

      expect(config['labels']['save']).to eq('Envoyer la suggestion')
    end

    it 'lets the host override a shipped label from its own locale files' do
      # Force the lazy load first; otherwise the next translate reloads from disk
      # and wipes the store_translations override before snippet reads it.
      I18n.t(:save, scope: :i18n_feedback, locale: :fr)
      I18n.backend.store_translations(:fr, i18n_feedback: { save: 'Soumettre' })

      config = config_from(described_class.snippet(endpoint: '/x', locale: :fr, active: false))

      expect(config['labels']['save']).to eq('Soumettre')
    ensure
      I18n.reload!
    end
  end

  describe '.snippet direction' do
    it 'marks right-to-left locales' do
      %i[ar ur].each do |locale|
        config = config_from(described_class.snippet(endpoint: '/x', locale: locale, active: false))
        expect(config['rtl']).to be(true), "expected #{locale} to be RTL"
      end
    end

    it 'treats a region variant by its language subtag' do
      config = config_from(described_class.snippet(endpoint: '/x', locale: 'ar-EG', active: false))
      expect(config['rtl']).to be(true)
    end

    it 'leaves left-to-right locales unmarked' do
      %i[en de ja].each do |locale|
        config = config_from(described_class.snippet(endpoint: '/x', locale: locale, active: false))
        expect(config['rtl']).to be(false), "expected #{locale} to be LTR"
      end
    end
  end

  describe '.snippet escaping' do
    it 'escapes </ so a config value cannot close the script block early' do
      I18nFeedback.config.pill_label = '</script><script>alert(1)</script>'

      snippet = described_class.snippet(endpoint: '/x', locale: :en, active: false)
      json = snippet[%r{data-i18n-feedback-config>(.*?)</script>}m, 1]

      # The extracted block stops at the real closing tag, so the payload must
      # not have introduced one of its own — yet the value round-trips intact.
      expect(json).not_to include('</script>')
      expect(config_from(snippet)['pillLabel']).to eq('</script><script>alert(1)</script>')
    end
  end
end
