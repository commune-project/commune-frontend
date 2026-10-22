module App.Context exposing (Active)

import Generated.I18n as Translations
import Locale exposing (Locale)


type alias Active =
    { locale : Locale
    , texts : Translations.I18n
    }
