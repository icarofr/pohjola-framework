-- | Posts feature views — Feed and Article templates.
module App.Features.Posts.View where

import Prelude

import App.Features.Posts.Types (Post, postBody, postExcerpt, postId, postTitle)
import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , FeedCard
  , PageTemplate(..)
  , articleSlots
  , feedSlots
  )
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe)
import Data.Route (Route(..))

renderPostList :: Lang -> Maybe FormStatus -> Array Post -> Html
renderPostList lang status posts =
  let
    d = (dict lang).posts
    nav = (dict lang).nav
  in
    renderPage lang PostList status
      ( Feed
          ( feedSlots
              d.listTitle
              d.listSubtitle
              [ PageHeader.breadcrumbHome lang nav.home
              , PageHeader.breadcrumbHere nav.posts
              ]
              (map (postToCard lang) posts)
          )
      )

renderPostDetail :: Lang -> Maybe FormStatus -> Post -> Html
renderPostDetail lang status post =
  let
    d = (dict lang).posts
    nav = (dict lang).nav
    idNum = postId post
    title = postTitle post
  in
    renderPage lang (PostDetail idNum) status
      ( Article
          ( articleSlots
              (d.articleTagPrefix <> show idNum)
              title
              d.unknownAuthor
              (d.articleTagPrefix <> show idNum)
              (postBody post)
              [ PageHeader.breadcrumbHome lang nav.home
              , PageHeader.breadcrumbLink lang PostList nav.posts
              , PageHeader.breadcrumbHere (d.articleTagPrefix <> show idNum)
              ]
          )
      )

renderPostsError :: Lang -> Maybe FormStatus -> Html
renderPostsError lang status =
  renderPostList lang status []

postToCard :: Lang -> Post -> FeedCard
postToCard lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    { imageUrl: postFeedImage idNum
    , imageAlt: postTitle post
    , date: d.articleTagPrefix <> show idNum
    , category: d.detailTitle
    , title: postTitle post
    , excerpt: postExcerpt post
    , authorName: d.unknownAuthor
    , authorRole: d.authorRole
    , target: Internal { lang, route: PostDetail idNum }
    }

postFeedImage :: Int -> String
postFeedImage id =
  case mod id 3 of
    0 -> "/images/service-1.svg"
    1 -> "/images/service-2.svg"
    _ -> "/images/service-3.svg"
