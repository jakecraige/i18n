require 'i18n/backend/base'
require 'i18n/backend/active_record/translation'

module I18n
  module Backend
    class ActiveRecord
      autoload :Missing,     'i18n/backend/active_record/missing'
      autoload :StoreProcs,  'i18n/backend/active_record/store_procs'
      autoload :Translation, 'i18n/backend/active_record/translation'

      include Base, Flatten

      def reload!
      end

      def available_locales
        begin
          Translation.available_locales
        rescue ::ActiveRecord::StatementInvalid
          []
        end
      end

      protected

        def lookup(locale, key, scope = [], options = {})
          key = normalize_keys(locale, key, scope, options[:separator])
          result = Translation.locale(locale).lookup(key).all

          if result.empty?
            nil
          elsif result.first.key == key
            result.first.value
          else
            chop_range = (key.size + FLATTEN_SEPARATOR.size)..-1
            result = result.inject({}) do |hash, r|
              hash[r.key.slice(chop_range)] = r.value
              hash
            end
            result.deep_symbolize_keys
          end
        end

        def merge_translations(locale, data, options = {})
          flatten_translations(locale, data).each do |key, value|
            Translation.locale(locale).lookup(expand_keys(key)).delete_all
            Translation.create(:locale => locale.to_s, :key => key.to_s, :value => value)
          end
        end

        # For a key :'foo.bar.baz' return ['foo', 'foo.bar', 'foo.bar.baz']
        def expand_keys(key)
          key.to_s.split(FLATTEN_SEPARATOR).inject([]) do |keys, key|
            keys << [keys.last, key].compact.join(FLATTEN_SEPARATOR)
          end
        end
    end
  end
end
