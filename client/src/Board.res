open Types

type state = {
  board: option<board>,
  loading: bool,
  error: option<string>,
}

type action =
  | FetchBoardStart
  | FetchBoardSuccess(board)
  | FetchBoardError(string)
  | AddCard(string, card)
  | MoveCard(string, string, string)
  | DeleteCard(string, string)

let reducer = (state, action) => {
  switch action {
  | FetchBoardStart => {...state, loading: true, error: None}
  | FetchBoardSuccess(board) => {board: Some(board), loading: false, error: None}
  | FetchBoardError(error) => {...state, loading: false, error: Some(error)}
  | AddCard(columnId, card) => 
      switch state.board {
      | Some(board) => {
          ...state,
          board: Some({
            columns: board.columns->Belt.Array.map(column => {
              if column.id === columnId {
                {...column, cards: Belt.Array.concat([card], column.cards)}
              } else {
                column
              }
            }),
          }),
        }
      | None => state
      }
  | MoveCard(cardId, fromColumnId, toColumnId) =>
      switch state.board {
      | Some(board) => {
          ...state,
          board: Some({
            columns: board.columns->Belt.Array.map(column => {
              if column.id === fromColumnId {
                {...column, cards: column.cards->Belt.Array.keep(card => card.id !== cardId)}
              } else if column.id === toColumnId {
                let cardToMove = board.columns
                  ->Belt.Array.getBy(col => col.id === fromColumnId)
                  ->Belt.Option.flatMap(col => col.cards->Belt.Array.getBy(card => card.id === cardId))
                
                switch cardToMove {
                | Some(card) => {...column, cards: Belt.Array.concat([card], column.cards)}
                | None => column
                }
              } else {
                column
              }
            }),
          }),
        }
      | None => state
      }
  | DeleteCard(columnId, cardId) =>
      switch state.board {
      | Some(board) => {
          ...state,
          board: Some({
            columns: board.columns->Belt.Array.map(column => {
              if column.id === columnId {
                {...column, cards: column.cards->Belt.Array.keep(card => card.id !== cardId)}
              } else {
                column
              }
            }),
          }),
        }
      | None => state
      }
  }
}

@react.component
let make = () => {
  let initialState = {board: None, loading: false, error: None}
  let (state, dispatch) = React.useReducer(reducer, initialState)
  
  let fetchBoard = () => {
    dispatch(FetchBoardStart)
    
    Api.fetchBoard()
    ->Js.Promise.then_(board => {
      dispatch(FetchBoardSuccess(board))
      Js.Promise.resolve()
    }, _)
    ->Js.Promise.catch(err => {
      let errorMsg = switch Js.Exn.message(Obj.magic(err)) {
      | Some(msg) => msg
      | None => "Unknown error occurred"
      }
      dispatch(FetchBoardError(errorMsg))
      Js.Promise.resolve()
    }, _)
    ->ignore
  }
  
  React.useEffect0(() => {
    fetchBoard()
    None
  })
  
  let handleAddCard = (columnId, card) => {
    Api.createCard(columnId, card)
    ->Js.Promise.then_(createdCard => {
      dispatch(AddCard(columnId, createdCard))
      Js.Promise.resolve()
    }, _)
    ->ignore
  }
  
  let handleMoveCard = (cardId, fromColumnId, toColumnId) => {
    Api.moveCard(cardId, fromColumnId, toColumnId)
    ->Js.Promise.then_(() => {
      dispatch(MoveCard(cardId, fromColumnId, toColumnId))
      Js.Promise.resolve()
    }, _)
    ->ignore
  }
  
  let handleDeleteCard = (cardId) => {
    // Find which column contains this card
    let columnId = switch state.board {
    | Some(board) => 
        board.columns
        ->Belt.Array.getBy(column => 
            column.cards->Belt.Array.getBy(card => card.id === cardId)->Belt.Option.isSome
        )
        ->Belt.Option.map(column => column.id)
    | None => None
    }
    
    switch columnId {
    | Some(colId) => 
        Api.deleteCard(cardId)
        ->Js.Promise.then_(() => {
          dispatch(DeleteCard(colId, cardId))
          Js.Promise.resolve()
        }, _)
        ->ignore
    | None => ()
    }
  }
  
  <div className="board-container">
    <header className="app-header">
      <h1> {React.string("OKanban")} </h1>
      <p> {React.string("Simple Kanban app written in OCaml")} </p>
    </header>
    
    {switch (state.loading, state.error, state.board) {
    | (true, _, _) => <div className="loading"> {React.string("Loading...")} </div>
    | (_, Some(error), _) => <div className="error"> {React.string("Error: " ++ error)} </div>
    | (_, _, Some(board)) => 
        <div className="board">
          {board.columns
            ->Belt.Array.map(column => 
                <Column 
                  key={column.id} 
                  column 
                  onAddCard={handleAddCard} 
                  onMoveCard={handleMoveCard}
                  onDeleteCard={handleDeleteCard}
                />
            )
            ->React.array}
        </div>
    | (false, None, None) => React.null
    }}
  </div>
}
