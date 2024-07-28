import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

pub type Position {
  Position(x: Int, y: Int)
}

pub type Car {
  Car(
    horizontal: Bool,
    label: String,
    position: Position,
    size: Int,
    target: Bool,
  )
}

pub type ExitPosition {
  TopExit(column: Int)
  LeftExit(row: Int)
  BottomExit(column: Int)
  RightExit(row: Int)
}

pub opaque type Game {
  Game(cars: List(Car), width: Int, height: Int, exit_position: ExitPosition)
}

pub fn new_game(
  width: Int,
  height: Int,
  exit_position: ExitPosition,
) -> Result(Game, String) {
  case width > 0, height > 0 {
    True, True -> {
      let exit_position_error = case exit_position {
        TopExit(column) ->
          case column < 0 || column >= width {
            True ->
              Some(
                "Top exit column must be between 0 and "
                <> int.to_string(width - 1)
                <> " inclusive",
              )
            False -> None
          }
        LeftExit(row) ->
          case row < 0 || row >= height {
            True ->
              Some(
                "Left exit row must be between 0 and "
                <> int.to_string(height - 1)
                <> " inclusive",
              )
            False -> None
          }
        BottomExit(column) ->
          case column < 0 || column >= width {
            True ->
              Some(
                "Bottom exit column must be between 0 and "
                <> int.to_string(width - 1)
                <> " inclusive",
              )
            False -> None
          }
        RightExit(row) ->
          case row < 0 || row >= height {
            True ->
              Some(
                "Right exit row must be between 0 and "
                <> int.to_string(height - 1)
                <> " inclusive",
              )
            False -> None
          }
      }

      case exit_position_error {
        Some(error) -> Error(error)
        None ->
          Ok(Game(
            cars: [],
            width: width,
            height: height,
            exit_position: exit_position,
          ))
      }
    }
    True, False -> Error("height must be greater than 0")
    False, True -> Error("width must be greater than 0")
    False, False -> Error("width and height must be greater than 0")
  }
}

pub fn add_car(game: Game, car: Car) -> Result(Game, String) {
  let result = Game(..game, cars: [car, ..game.cars])

  case game_cars_valid(result) {
    Ok(_) -> Ok(result)
    Error(error) -> Error(error)
  }
}

fn game_cars_valid(game: Game) -> Result(Nil, String) {
  let result =
    list.find_map(game.cars, fn(car) {
      case car.size > 0 {
        False -> Ok("Car size must be greater than 0")
        True -> {
          let end_position = case car.horizontal {
            True -> Position(x: car.position.x + car.size, y: car.position.y)
            False -> Position(x: car.position.x, y: car.position.y + car.size)
          }

          case
            car.position.x < 0
            || car.position.y < 0
            || end_position.x > game.width
            || end_position.y > game.height
          {
            True -> Ok("Car position is outside of the game field")
            False -> Error(Nil)
          }
        }
      }
    })

  case result {
    Ok(error) -> Error(error)
    _ -> {
      let #(result, _) =
        list.fold_until(game.cars, #(Ok(Nil), dict.new()), fn(state, car) {
          let #(error, state) =
            list.fold_until(list.range(0, car.size - 1), state, fn(state, i) {
              let #(_, state) = state

              let position = case car.horizontal {
                True -> Position(x: car.position.x + i, y: car.position.y)
                False -> Position(x: car.position.x, y: car.position.y + i)
              }

              case dict.has_key(state, position) {
                True ->
                  list.Stop(#(
                    Error(
                      "Car collition detected at position ("
                      <> int.to_string(position.x)
                      <> ", "
                      <> int.to_string(position.y)
                      <> ")",
                    ),
                    state,
                  ))
                False ->
                  list.Continue(#(Ok(Nil), dict.insert(state, position, Nil)))
              }
            })

          case error {
            Ok(_) -> list.Continue(#(Ok(Nil), state))
            Error(error) -> list.Stop(#(Error(error), state))
          }
        })
      result
    }
  }
}

pub fn car_at(game: Game, position: Position) -> Option(Car) {
  let car =
    list.find(game.cars, fn(car) {
      case car.horizontal {
        True ->
          car.position.y == position.y
          && car.position.x <= position.x
          && car.position.x + car.size > position.x
        False ->
          car.position.x == position.x
          && car.position.y <= position.y
          && car.position.y + car.size > position.y
      }
    })

  case car {
    Ok(car) -> Some(car)
    Error(_) -> None
  }
}
