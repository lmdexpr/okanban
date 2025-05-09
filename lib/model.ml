type card_id = string [@@deriving yojson]

type card = {
  id : card_id;
  title : string;
  description : string option;
  created_at : float;
  due_date : float option;
  webhook_url : string option;
} [@@deriving yojson, fields]

type column_id = string [@@deriving yojson]

type column = {
  id : column_id;
  name : string;
  cards : card list;
} [@@deriving yojson, fields]

type board = {
  columns : column list;
} [@@deriving yojson, fields]

(* In-memory database for simplicity *)
let board = ref {
  columns = [
    {
      id = "todo";
      name = "To Do";
      cards = [];
    };
    {
      id = "in-progress";
      name = "In Progress";
      cards = [];
    };
    {
      id = "done";
      name = "Done";
      cards = [];
    };
  ];
}

(* Helper functions *)
let generate_id () =
  let random = Random.int 1000000 in
  let timestamp = int_of_float (Unix.time ()) in
  string_of_int timestamp ^ string_of_int random

let find_column column_id =
  List.find_opt (fun column -> column.id = column_id) !board.columns

let update_column column =
  let columns = List.map (fun c -> if c.id = column.id then column else c) !board.columns in
  board := { columns }

let find_card card_id =
  let rec find_in_columns = function
    | [] -> None
    | column :: rest ->
        match List.find_opt (fun (card : card) -> card.id = card_id) column.cards with
        | Some card -> Some (card, column)
        | None -> find_in_columns rest
  in
  find_in_columns !board.columns

let add_card column_id card =
  match find_column column_id with
  | Some column ->
      let updated_column = { column with cards = card :: column.cards } in
      update_column updated_column;
      Ok card
  | None -> Error "Column not found"

let update_card (card : card) =
  match find_card card.id with
  | Some (_, column) ->
      let updated_cards = List.map (fun (c : card) -> if c.id = card.id then card else c) column.cards in
      let updated_column = { column with cards = updated_cards } in
      update_column updated_column;
      Ok card
  | None -> Error "Card not found"

let move_card card_id from_column_id to_column_id =
  match (find_column from_column_id, find_column to_column_id) with
  | Some from_column, Some to_column ->
      let card_opt = List.find_opt (fun (card : card) -> card.id = card_id) from_column.cards in
      (match card_opt with
      | Some card ->
          let from_cards = List.filter (fun (card : card) -> card.id <> card_id) from_column.cards in
          let to_cards = card :: to_column.cards in
          update_column { from_column with cards = from_cards };
          update_column { to_column with cards = to_cards };
          Ok card
      | None -> Error "Card not found in source column")
  | None, _ -> Error "Source column not found"
  | _, None -> Error "Destination column not found"

let delete_card card_id =
  match find_card card_id with
  | Some (card, column) ->
      let updated_cards = List.filter (fun (c : card) -> c.id <> card_id) column.cards in
      let updated_column = { column with cards = updated_cards } in
      update_column updated_column;
      Ok card
  | None -> Error "Card not found"

(* Webhook reminder functionality *)
let check_due_cards () =
  let now = Unix.time () in
  let due_cards = 
    List.fold_left (fun acc column ->
      let column_due_cards = 
        List.filter (fun card -> 
          match card.due_date, card.webhook_url with
          | Some due, Some _url when due <= now -> true
          | _ -> false
        ) column.cards
      in
      acc @ column_due_cards
    ) [] !board.columns
  in
  due_cards

let send_webhook card =
  match card.webhook_url with
  | Some _url -> 
    (* todo *)
    Lwt.return true
  | None -> Lwt.return false
