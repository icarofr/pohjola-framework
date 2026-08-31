-- | Posts feature views — Feed and Article templates.
module App.Features.Posts.View where

import Prelude

import App.Features.Posts.Types (Post, postBody, postExcerpt, postId, postTitle)
import App.Html (Html)
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , FeedCard
  , PageTemplate(..)
  , articleSlots
  , feedSlots
  )
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  let
    d = (dict lang).posts
  in
    renderPage lang PostList
      ( Feed
          ( feedSlots
              d.listTitle
              d.listTitle
              (map (postToCard lang) posts)
          )
      )

renderPostDetail :: Lang -> Post -> Html
renderPostDetail lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    renderPage lang (PostDetail idNum)
      ( Article
          ( articleSlots
              (d.articleTagPrefix <> show idNum)
              (postTitle post)
              d.unknownAuthor
              (d.articleTagPrefix <> show idNum)
              (postBody post)
              d.backToList
          )
      )

renderPostsError :: Lang -> Html
renderPostsError lang =
  renderPostList lang []

postToCard :: Lang -> Post -> FeedCard
postToCard lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    { imageUrl: "/images/service-2.svg"
    , imageAlt: postTitle post
    , date: d.articleTagPrefix <> show idNum
    , category: d.detailTitle
    , title: postTitle post
    , excerpt: postExcerpt post
    , authorName: d.unknownAuthor
    , authorRole: d.authorRole
    , target: Internal { lang, route: PostDetail idNum }
    }
