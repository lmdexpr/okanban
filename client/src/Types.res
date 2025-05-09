type card = {
  id: string,
  title: string,
  description: option<string>,
  created_at: float,
  due_date: option<float>,
  webhook_url: option<string>,
}

type column = {
  id: string,
  name: string,
  cards: array<card>,
}

type board = {
  columns: array<column>,
}

type moveCardPayload = {
  from_column_id: string,
  to_column_id: string,
}
