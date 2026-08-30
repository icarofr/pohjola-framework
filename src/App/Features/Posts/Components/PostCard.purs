-- | PostCard — maps Post domain values into App.Ui teaserCard
module App.Features.Posts.Components.PostCard (renderPostCard) where

import Prelude

import App.Features.Posts.Types (Post, postExcerpt, postId, postTitle)
import App.Html (Html)
import App.Ui as Ui
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderPostCard :: Lang -> Post -> Html
renderPostCard lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    Ui.teaserCard
      { meta: Just (d.articleTagPrefix <> show idNum)
      , title: postTitle post
      , excerpt: postExcerpt post
      , action:
          { label: d.readMore <> " →"
          , target: Ui.Internal { lang, route: PostDetail idNum }
          }
      }
