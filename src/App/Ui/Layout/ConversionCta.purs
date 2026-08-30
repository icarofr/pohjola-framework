-- | Conversion CTA — thin wrapper over conversionSection
module App.Ui.Layout.ConversionCta
  ( ConversionCtaProps
  , conversionCta
  ) where

import App.Html (Html)
import App.Ui.Layout.PageSection (conversionSection)
import App.Ui.Layout.Types (ActionTarget)

type ConversionCtaProps =
  { heading :: String
  , body :: String
  , action ::
      { label :: String
      , target :: ActionTarget
      }
  }

conversionCta :: ConversionCtaProps -> Html
conversionCta props =
  conversionSection
    { heading: props.heading
    , body: props.body
    , action: props.action
    }
