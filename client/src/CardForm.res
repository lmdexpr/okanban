open Types

type state = {
  title: string,
  description: string,
  due_date: string,
  webhook_url: string,
}

type action =
  | SetTitle(string)
  | SetDescription(string)
  | SetDueDate(string)
  | SetWebhookUrl(string)
  | Reset

let initialState = {
  title: "",
  description: "",
  due_date: "",
  webhook_url: "",
}

let reducer = (state, action) => {
  switch action {
  | SetTitle(title) => {...state, title}
  | SetDescription(description) => {...state, description}
  | SetDueDate(due_date) => {...state, due_date}
  | SetWebhookUrl(webhook_url) => {...state, webhook_url}
  | Reset => initialState
  }
}

@react.component
let make = (~columnId as _, ~onSubmit) => {
  let (state, dispatch) = React.useReducer(reducer, initialState)
  
  let handleSubmit = event => {
    ReactEvent.Form.preventDefault(event)
    
    if state.title !== "" {
      let due_date = switch state.due_date {
      | "" => None
      | dateStr => 
          try {
            let date = Js.Date.fromString(dateStr)
            Some(Js.Date.getTime(date) /. 1000.0)
          } catch {
          | _ => None
          }
      }
      
      let description = switch state.description {
      | "" => None
      | desc => Some(desc)
      }
      
      let webhook_url = switch state.webhook_url {
      | "" => None
      | url => Some(url)
      }
      
      let card = {
        id: "", // Will be set by the server
        title: state.title,
        description,
        created_at: Js.Date.now() /. 1000.0,
        due_date,
        webhook_url,
      }
      
      onSubmit(card)
      dispatch(Reset)
    }
  }
  
  <div className="card-form">
    <h3> {React.string("Add New Card")} </h3>
    <form onSubmit={handleSubmit}>
      <div className="form-group">
        <label htmlFor="title"> {React.string("Title:")} </label>
        <input
          type_="text"
          id="title"
          value={state.title}
          onChange={e => dispatch(SetTitle(ReactEvent.Form.target(e)["value"]))}
          required={true}
        />
      </div>
      
      <div className="form-group">
        <label htmlFor="description"> {React.string("Description:")} </label>
        <textarea
          id="description"
          value={state.description}
          onChange={e => dispatch(SetDescription(ReactEvent.Form.target(e)["value"]))}
        />
      </div>
      
      <div className="form-group">
        <label htmlFor="due_date"> {React.string("Due Date:")} </label>
        <input
          type_="datetime-local"
          id="due_date"
          value={state.due_date}
          onChange={e => dispatch(SetDueDate(ReactEvent.Form.target(e)["value"]))}
        />
      </div>
      
      <div className="form-group">
        <label htmlFor="webhook_url"> {React.string("Webhook URL:")} </label>
        <input
          type_="url"
          id="webhook_url"
          value={state.webhook_url}
          onChange={e => dispatch(SetWebhookUrl(ReactEvent.Form.target(e)["value"]))}
          placeholder="https://example.com/webhook"
        />
      </div>
      
      <button type_="submit"> {React.string("Add Card")} </button>
    </form>
  </div>
}
