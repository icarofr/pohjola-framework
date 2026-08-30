-- | Posts feature views — list and detail via App.Ui blueprints
module App.Features.Posts.View where

import Prelude

import App.Features.Posts.Components.PostCard (renderPostCard)
import App.Features.Posts.Types (Post, postBody, postId, postTitle)
import App.Html (Html)
import App.Ui as Ui
import Data.Array (null)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  let
    d = (dict lang).posts
    navDict = (dict lang).nav
  in
    Ui.feedPage
      { category: Just navDict.posts
      , title: d.listTitle
      , subtitle: Nothing
      , items: map (renderPostCard lang) posts
      , empty:
          if null posts then
            Just
              { title: d.notFound
              , description: d.loadingError
              , action: Nothing
              }
          else
            Nothing
      }

renderPostDetail :: Lang -> Post -> Html
renderPostDetail lang post =
  let
    d = (dict lang).posts
    idNum = postId post
  in
    Ui.articlePage
      { back: { label: d.backToList, lang, route: PostList }
      , metaTag: d.articleTagPrefix <> show idNum
      , title: postTitle post
      , authorName: d.unknownAuthor
      , authorSubtitle: Nothing
      , body: postBody post
      }

renderPostsError :: Lang -> Html
renderPostsError lang =
  let
    d = (dict lang).posts
    navDict = (dict lang).nav
  in
    Ui.feedPage
      { category: Just navDict.posts
      , title: d.listTitle
      , subtitle: Nothing
      , items: []
      , empty:
          Just
            { title: d.loadingError
            , description: d.notFound
            , action:
                Just
                  ( Ui.buttonLink
                      { variant: Ui.ButtonPrimary
                      , size: Ui.Sm
                      , lang
                      , route: PostList
                      }
                      d.backToList
                  )
            }
      }
