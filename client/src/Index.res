switch (ReactDOM.querySelector("#root")) {
| Some(rootElement) => {
    ReactDOM.render(
      <Board />,
      rootElement
    )
  }
| None => Js.Console.error("Could not find root element")
}
