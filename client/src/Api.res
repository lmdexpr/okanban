open Types

let fetchBoard = () => {
  Js.Promise.make((~resolve, ~reject) => {
    Fetch.fetch("/api/board")->Js.Promise.then_(Fetch.Response.json, _)->Js.Promise.then_(json => {
      let board = json->Js.Json.decodeObject->Belt.Option.getExn
      let columns =
        board->Js.Dict.get("columns")->Belt.Option.getExn->Js.Json.decodeArray->Belt.Option.getExn

      let parsedColumns = columns->Belt.Array.map(
        columnJson => {
          let column = columnJson->Js.Json.decodeObject->Belt.Option.getExn
          let id =
            column->Js.Dict.get("id")->Belt.Option.getExn->Js.Json.decodeString->Belt.Option.getExn
          let name =
            column
            ->Js.Dict.get("name")
            ->Belt.Option.getExn
            ->Js.Json.decodeString
            ->Belt.Option.getExn
          let cardsJson =
            column
            ->Js.Dict.get("cards")
            ->Belt.Option.getExn
            ->Js.Json.decodeArray
            ->Belt.Option.getExn

          let cards = cardsJson->Belt.Array.map(
            cardJson => {
              let card = cardJson->Js.Json.decodeObject->Belt.Option.getExn
              let id =
                card
                ->Js.Dict.get("id")
                ->Belt.Option.getExn
                ->Js.Json.decodeString
                ->Belt.Option.getExn
              let title =
                card
                ->Js.Dict.get("title")
                ->Belt.Option.getExn
                ->Js.Json.decodeString
                ->Belt.Option.getExn
              let created_at =
                card
                ->Js.Dict.get("created_at")
                ->Belt.Option.getExn
                ->Js.Json.decodeNumber
                ->Belt.Option.getExn

              let description =
                card
                ->Js.Dict.get("description")
                ->Belt.Option.flatMap(json => json->Js.Json.decodeString)

              let due_date =
                card
                ->Js.Dict.get("due_date")
                ->Belt.Option.flatMap(json => json->Js.Json.decodeNumber)

              let webhook_url =
                card
                ->Js.Dict.get("webhook_url")
                ->Belt.Option.flatMap(json => json->Js.Json.decodeString)

              {
                id,
                title,
                description,
                created_at,
                due_date,
                webhook_url,
              }
            },
          )

          {
            id,
            name,
            cards,
          }
        },
      )

      let result = {columns: parsedColumns}
      resolve(. result)
      Js.Promise.resolve(result)
    }, _)->Js.Promise.catch(err => {
      Js.Console.error(err)
      reject(. Js.Exn.raiseError("Failed to fetch board"))
      Js.Promise.resolve({columns: []})
    }, _)->ignore
  })
}

let createCard = (columnId, card) => {
  let body = Js.Dict.empty()
  Js.Dict.set(body, "title", Js.Json.string(card.title))

  switch card.description {
  | Some(desc) => Js.Dict.set(body, "description", Js.Json.string(desc))
  | None => ()
  }

  switch card.due_date {
  | Some(date) => Js.Dict.set(body, "due_date", Js.Json.number(date))
  | None => ()
  }

  switch card.webhook_url {
  | Some(url) => Js.Dict.set(body, "webhook_url", Js.Json.string(url))
  | None => ()
  }

  let bodyJson = Js.Json.object_(body)

  Js.Promise.make((~resolve, ~reject) => {
    Fetch.fetchWithInit(
      `/api/columns/${columnId}/cards`,
      Fetch.RequestInit.make(
        ~method_=Post,
        ~body=Fetch.BodyInit.make(Js.Json.stringify(bodyJson)),
        ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
        (),
      ),
    )
    ->Js.Promise.then_(Fetch.Response.json, _)
    ->Js.Promise.then_(json => {
      let cardObj = json->Js.Json.decodeObject->Belt.Option.getExn
      let id =
        cardObj->Js.Dict.get("id")->Belt.Option.getExn->Js.Json.decodeString->Belt.Option.getExn

      let result = {...card, id}
      resolve(. result)
      Js.Promise.resolve(result)
    }, _)
    ->Js.Promise.catch(err => {
      Js.Console.error(err)
      reject(. Js.Exn.raiseError("Failed to create card"))
      Js.Promise.resolve(card)
    }, _)
    ->ignore
  })
}

let updateCard = (card: card) => {
  let body = Js.Dict.empty()
  Js.Dict.set(body, "id", Js.Json.string(card.id))
  Js.Dict.set(body, "title", Js.Json.string(card.title))
  Js.Dict.set(body, "created_at", Js.Json.number(card.created_at))

  switch card.description {
  | Some(desc) => Js.Dict.set(body, "description", Js.Json.string(desc))
  | None => Js.Dict.set(body, "description", Js.Json.null)
  }

  switch card.due_date {
  | Some(date) => Js.Dict.set(body, "due_date", Js.Json.number(date))
  | None => Js.Dict.set(body, "due_date", Js.Json.null)
  }

  switch card.webhook_url {
  | Some(url) => Js.Dict.set(body, "webhook_url", Js.Json.string(url))
  | None => Js.Dict.set(body, "webhook_url", Js.Json.null)
  }

  let bodyJson = Js.Json.object_(body)

  Js.Promise.make((~resolve, ~reject) => {
    Fetch.fetchWithInit(
      `/api/cards/${card.id}`,
      Fetch.RequestInit.make(
        ~method_=Put,
        ~body=Fetch.BodyInit.make(Js.Json.stringify(bodyJson)),
        ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
        (),
      ),
    )
    ->Js.Promise.then_(Fetch.Response.json, _)
    ->Js.Promise.then_(json => {
      resolve(. card)
      Js.Promise.resolve(card)
    }, _)
    ->Js.Promise.catch(err => {
      Js.Console.error(err)
      reject(. Js.Exn.raiseError("Failed to update card"))
      Js.Promise.resolve(card)
    }, _)
    ->ignore
  })
}

let moveCard = (cardId, fromColumnId, toColumnId) => {
  let body = Js.Dict.empty()
  Js.Dict.set(body, "from_column_id", Js.Json.string(fromColumnId))
  Js.Dict.set(body, "to_column_id", Js.Json.string(toColumnId))

  let bodyJson = Js.Json.object_(body)

  Js.Promise.make((~resolve, ~reject) => {
    Fetch.fetchWithInit(
      `/api/cards/${cardId}/move`,
      Fetch.RequestInit.make(
        ~method_=Post,
        ~body=Fetch.BodyInit.make(Js.Json.stringify(bodyJson)),
        ~headers=Fetch.HeadersInit.make({"Content-Type": "application/json"}),
        (),
      ),
    )
    ->Js.Promise.then_(Fetch.Response.json, _)
    ->Js.Promise.then_(json => {
      resolve(. ())
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(err => {
      Js.Console.error(err)
      reject(. Js.Exn.raiseError("Failed to move card"))
      Js.Promise.resolve()
    }, _)
    ->ignore
  })
}

let deleteCard = cardId => {
  Js.Promise.make((~resolve, ~reject) => {
    Fetch.fetchWithInit(`/api/cards/${cardId}`, Fetch.RequestInit.make(~method_=Delete, ()))
    ->Js.Promise.then_(response => {
      resolve(. ())
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(err => {
      Js.Console.error(err)
      reject(. Js.Exn.raiseError("Failed to delete card"))
      Js.Promise.resolve()
    }, _)
    ->ignore
  })
}
