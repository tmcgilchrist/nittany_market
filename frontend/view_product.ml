open! Core
open! Bonsai_web
open Bonsai.Let_syntax
module G = Nittany_market_frontend_graphql

let deoptionize x = match x with Some x -> x | None -> ""

let get_slug path =
  let re = Js_of_ocaml.Regexp.regexp "^/products/?(.*)/?$" in
  let plid_match = Js_of_ocaml.Regexp.string_match re path 0 in
  plid_match
  |> Option.bind ~f:(fun m -> Js_of_ocaml.Regexp.matched_group m 1)
  |> Option.map ~f:Js_of_ocaml.Url.urldecode

let display_reviews
    (product_listing : G.Queries.ProductListingFields.t_product_listing) =
  let review_cards =
    Array.to_list
      (Array.map product_listing.reviews ~f:(fun r ->
           Templates.card ~extra_classes:[ "py-2" ]
             (Vdom.Node.text (Printf.sprintf "By: %s" r.buyer_email))
             (Vdom.Node.text r.description)))
  in
  Vdom.Node.div
    [
      Vdom.Node.h4 [ Vdom.Node.text "Reviews" ];
      (if List.length review_cards > 0 then Vdom.Node.div review_cards
      else Vdom.Node.text "No Reviews Found");
    ]

let display_product
    (product_listing :
      G.Queries.ProductListingFields.t_product_listing option Value.t) =
  let%arr product_listing = product_listing in
  match product_listing with
  | None -> Vdom.Node.text "Product Not Found"
  | Some product_listing ->
      Vdom.Node.div
        [
          Vdom.Node.p
            [
              Vdom.Node.h2 [ Vdom.Node.text product_listing.title ];
              Templates.bullet "Product Name" product_listing.product_name;
              Templates.bullet "Product Description"
                product_listing.product_description;
              Templates.bullet "Price" product_listing.price;
              Templates.bullet "Quantity"
                (Int.to_string product_listing.quantity);
              (match product_listing.seller with
              | Some s -> Templates.bullet "Sold By" s.email
              | None -> Vdom.Node.none);
              Templates.bullet_vdom "Category"
                (Route.link_path_vdom
                   (Util.category_path product_listing.category_name)
                   ~children:(Vdom.Node.text product_listing.category_name));
            ];
          Vdom.Node.hr ();
          display_reviews product_listing;
        ]

let component =
  let module ProductListing = G.Queries.ProductListingQuery in
  let module Loader = Graphql_loader.ForQuery (ProductListing) in
  Loader.component
    (fun product_query ->
      let product =
        Value.map ~f:(fun data -> data.product_listing) product_query
      in
      display_product product)
    (Value.map
       ~f:(fun v ->
         ProductListing.makeVariables
           ~id:(Int.of_string (deoptionize @@ get_slug v))
           ())
       Route.curr_path)
