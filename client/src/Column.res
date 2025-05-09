open Types

@react.component
let make = (~column, ~onAddCard, ~onMoveCard, ~onDeleteCard) => {
  let handleDragOver = e => {
    ReactEvent.Mouse.preventDefault(e)
  }
  
  let handleDrop = e => {
    ReactEvent.Mouse.preventDefault(e)
    let dataTransfer = ReactEvent.Synthetic.nativeEvent(e)["dataTransfer"]
    let cardId = dataTransfer["getData"]("cardId")
    let sourceColumnId = dataTransfer["getData"]("sourceColumnId")
    
    if sourceColumnId !== column.id {
      onMoveCard(cardId, sourceColumnId, column.id)
    }
  }
  
  <div className="column" onDragOver={handleDragOver} onDrop={handleDrop}>
    <div className="column-header">
      <h2> {React.string(column.name)} </h2>
      <span className="card-count"> {React.string(Belt.Int.toString(Belt.Array.length(column.cards)))} </span>
    </div>
    
    <div className="cards">
      {Belt.Array.map(column.cards, card => 
        <Card 
          key={card.id} 
          card 
          columnId={column.id} 
          onMove={onMoveCard} 
          onDelete={onDeleteCard} 
        />
      )->React.array}
    </div>
    
    <CardForm columnId={column.id} onSubmit={card => onAddCard(column.id, card)} />
  </div>
}
