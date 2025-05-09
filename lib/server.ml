open Model
open Lwt.Infix

(* API handlers *)
let get_board_handler _request =
  let json = board_to_yojson !board in
  Dream.json (Yojson.Safe.to_string json)

let create_card_handler request =
  Dream.body request >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let column_id = Dream.param request "column_id" in
    let title = json |> Yojson.Safe.Util.member "title" |> Yojson.Safe.Util.to_string in
    let description = 
      try Some (json |> Yojson.Safe.Util.member "description" |> Yojson.Safe.Util.to_string)
      with _ -> None
    in
    let due_date =
      try Some (json |> Yojson.Safe.Util.member "due_date" |> Yojson.Safe.Util.to_float)
      with _ -> None
    in
    let webhook_url =
      try Some (json |> Yojson.Safe.Util.member "webhook_url" |> Yojson.Safe.Util.to_string)
      with _ -> None
    in
    
    let card = {
      id = generate_id ();
      title;
      description;
      created_at = Unix.time ();
      due_date;
      webhook_url;
    } in
    
    match add_card column_id card with
    | Ok card -> Dream.json (Yojson.Safe.to_string (card_to_yojson card))
    | Error msg -> Lwt.return @@ Dream.response ~status:`Bad_Request msg
  with e ->
    Lwt.return @@ Dream.response ~status:`Bad_Request (Printexc.to_string e)

let update_card_handler request =
  Dream.body request >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let card_id = Dream.param request "card_id" in
    let card_json = card_of_yojson json |> Result.get_ok in
    
    if card_id <> card_json.id then
      Lwt.return @@ Dream.response ~status:`Bad_Request "Card ID mismatch"
    else
      match update_card card_json with
      | Ok card -> Dream.json (Yojson.Safe.to_string (card_to_yojson card))
      | Error msg -> Lwt.return @@ Dream.response ~status:`Bad_Request msg
  with e ->
    Lwt.return @@ Dream.response ~status:`Bad_Request (Printexc.to_string e)

let move_card_handler request =
  Dream.body request >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let card_id = Dream.param request "card_id" in
    let from_column_id = json |> Yojson.Safe.Util.member "from_column_id" |> Yojson.Safe.Util.to_string in
    let to_column_id = json |> Yojson.Safe.Util.member "to_column_id" |> Yojson.Safe.Util.to_string in
    
    match move_card card_id from_column_id to_column_id with
    | Ok card -> Dream.json (Yojson.Safe.to_string (card_to_yojson card))
    | Error msg -> Lwt.return @@ Dream.response ~status:`Bad_Request msg
  with e ->
    Lwt.return @@ Dream.response ~status:`Bad_Request (Printexc.to_string e)

let delete_card_handler request =
  let card_id = Dream.param request "card_id" in
  match delete_card card_id with
  | Ok _ -> Dream.empty `OK
  | Error msg -> Lwt.return @@ Dream.response ~status:`Bad_Request msg

(* Webhook reminder background task *)
let reminder_task () =
  let rec loop () =
    Lwt_unix.sleep 60.0 >>= fun () ->
    let due_cards = check_due_cards () in
    Lwt_list.iter_p (fun card ->
      send_webhook card >>= fun success ->
      if success then
        Dream.log "Sent reminder webhook for card %s" card.id
      else
        Dream.log "Failed to send reminder webhook for card %s" card.id;
      Lwt.return_unit
    ) due_cards
    >>= fun () ->
    loop ()
  in
  loop ()

let index _ =
  Dream.html "\
<!DOCTYPE html>\
<html lang=\"en\">\
<head>\
  <meta charset=\"UTF-8\">\
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
  <title>OKanban - Simple Kanban App</title>\
  <link rel=\"stylesheet\" href=\"/static/styles.css\">\
</head>\
<body>\
  <div id=\"root\"></div>\
  <script src=\"/static/bundle.js\"></script>\
</body>\
</html>\
"

(* Server setup *)
let start () =
  Random.self_init ();
  
  (* Start the reminder task *)
  let _ = reminder_task () in
  
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" index;

    Dream.get "/static/**" (Dream.static "public");
    
    (* API routes *)
    Dream.get "/api/board" get_board_handler;
    Dream.post "/api/columns/:column_id/cards" create_card_handler;
    Dream.put "/api/cards/:card_id" update_card_handler;
    Dream.post "/api/cards/:card_id/move" move_card_handler;
    Dream.delete "/api/cards/:card_id" delete_card_handler;
  ]
