open Types

@react.component
let make = (~card, ~columnId, ~onMove as _, ~onDelete) => {
  let formatDate = timestamp => {
    let date = Js.Date.fromFloat(timestamp *. 1000.0)
    Js.Date.toLocaleDateString(date) ++ " " ++ Js.Date.toLocaleTimeString(date)
  }
  
  let isDue = switch card.due_date {
  | Some(due) => due < Js.Date.now() /. 1000.0
  | None => false
  }
  
  let cardClass = isDue ? "card due" : "card"
  
  <div className={cardClass} draggable={true} onDragStart={e => {
    let dataTransfer = ReactEvent.Synthetic.nativeEvent(e)["dataTransfer"]
    ignore(dataTransfer["setData"]("cardId", card.id))
    ignore(dataTransfer["setData"]("sourceColumnId", columnId))
  }}>
    <div className="card-header">
      <h3> {React.string(card.title)} </h3>
      <button className="delete-btn" onClick={_ => onDelete(card.id)}>
        {React.string("×")}
      </button>
    </div>
    
    {switch card.description {
    | Some(desc) => <p className="card-description"> {React.string(desc)} </p>
    | None => React.null
    }}
    
    <div className="card-meta">
      <p> {React.string("Created: " ++ formatDate(card.created_at))} </p>
      
      {switch card.due_date {
      | Some(due) => 
          <p className={isDue ? "due-date overdue" : "due-date"}>
            {React.string("Due: " ++ formatDate(due))}
          </p>
      | None => React.null
      }}
      
      {switch card.webhook_url {
      | Some(_) => <p className="webhook-indicator"> {React.string("⏰ Reminder set")} </p>
      | None => React.null
      }}
    </div>
  </div>
}
