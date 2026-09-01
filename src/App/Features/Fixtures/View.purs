-- | Fixtures view — Schedule template slots with crests (OneFootball data).
module App.Features.Fixtures.View where

import Prelude

import App.Html (Html)
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , PageTemplate(..)
  , ScheduleMatch
  , scheduleSlots
  )
import Data.Content
  ( Fixture
  , FixtureVenue(..)
  , fixtureKickoff
  , fixtureTitle
  , onefootballFixturesUrl
  , spursCrest
  , spursCrestAlt
  , tottenhamFixtures
  )
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

type FixturesCopy =
  { listTitle :: String
  , subtitle :: String
  , homeLabel :: String
  , awayLabel :: String
  , homeVenue :: String
  , awayVenue :: String
  , sourceLabel :: String
  , vsLabel :: String
  }

renderFixtures :: Lang -> Html
renderFixtures lang =
  let
    d = (dict lang).fixtures
  in
    renderPage lang Fixtures
      ( Schedule
          ( scheduleSlots
              d.listTitle
              d.subtitle
              (map (fixtureToMatch d) tottenhamFixtures)
          )
      )

fixtureToMatch :: FixturesCopy -> Fixture -> ScheduleMatch
fixtureToMatch d fixture =
  let
    opponentCrest = { src: fixture.opponentCrest, alt: fixture.opponent }
    spurs = { src: spursCrest, alt: spursCrestAlt }
    crests =
      case fixture.venue of
        SpursHome -> { home: spurs, away: opponentCrest }
        SpursAway -> { home: opponentCrest, away: spurs }
  in
    { home: crests.home
    , away: crests.away
    , vsLabel: d.vsLabel
    , title: fixtureTitle fixture
    , kickoff: fixtureKickoff fixture
    , competition: fixture.competition
    , detail: venueLine d fixture.venue
    , target: External { href: onefootballFixturesUrl }
    }

venueLine :: FixturesCopy -> FixtureVenue -> String
venueLine d venue =
  case venue of
    SpursHome -> d.homeLabel <> " · " <> d.homeVenue
    SpursAway -> d.awayLabel <> " · " <> d.awayVenue
